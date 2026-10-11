#define _GNU_SOURCE
#include <ctype.h>
#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#define MAX_CANDIDATES 80
#define MAX_SIGNATURES 12
#define MAX_LINE 512
#define MAX_DECLARATION 400
#define MAX_PATH 768
#define MAX_FILE_BYTES 524288

typedef struct Signature {
    char text[MAX_LINE];
} Signature;

typedef struct SourceFile {
    char relative_path[MAX_PATH];
    char purpose[160];
    int relevance;
    int signature_count;
    Signature signatures[MAX_SIGNATURES];
} SourceFile;

static char project_root[MAX_PATH];
static char query_text[512];
static char language_filter[16];
static SourceFile candidates[MAX_CANDIDATES];
static int candidate_count;

static int path_is_skipped(const char *path_text) {
    static const char *fragments[] = {
        "node_modules", "dist", "/target/", "__pycache__", "/.git/",
        "cmake-build", "CMakeFiles", "/build/", "third_party", "/vendor/",
        "/venv/", "/env/", NULL
    };
    for (int fragment_index = 0; fragments[fragment_index] != NULL; fragment_index++) {
        if (strstr(path_text, fragments[fragment_index]) != NULL) {
            return 1;
        }
    }
    return 0;
}

static int extension_language(const char *path_text, char *language_name, size_t language_size) {
    const char *extension = strrchr(path_text, '.');
    if (extension == NULL) {
        return 0;
    }
    if (strcmp(extension, ".c") == 0 || strcmp(extension, ".h") == 0) {
        snprintf(language_name, language_size, "c");
        return 1;
    }
    if (strcmp(extension, ".cc") == 0 || strcmp(extension, ".cpp") == 0 ||
        strcmp(extension, ".cxx") == 0 || strcmp(extension, ".hpp") == 0 ||
        strcmp(extension, ".hh") == 0 || strcmp(extension, ".hxx") == 0) {
        snprintf(language_name, language_size, "cpp");
        return 1;
    }
    return 0;
}

static int language_selected(const char *language_name) {
    if (language_filter[0] == '\0' || strcmp(language_filter, "all") == 0) {
        return 1;
    }
    if (strcmp(language_filter, "cpp") == 0) {
        return strcmp(language_name, "cpp") == 0 || strcmp(language_name, "c") == 0;
    }
    return strcmp(language_filter, language_name) == 0;
}

static int score_source(const char *path_text, const char *content) {
    int score = 0;
    char lowered_path[MAX_PATH];
    snprintf(lowered_path, sizeof lowered_path, "%s", path_text);
    for (char *cursor = lowered_path; *cursor != '\0'; cursor++) {
        *cursor = (char)tolower((unsigned char)*cursor);
    }
    if (strstr(lowered_path, "core") || strstr(lowered_path, "src") || strstr(lowered_path, "include") ||
        strstr(lowered_path, "main")) {
        score += 25;
    }
    if (strstr(lowered_path, "test") || strstr(lowered_path, "spec")) {
        score -= 60;
    }
    char query_copy[512];
    snprintf(query_copy, sizeof query_copy, "%s", query_text);
    char *keyword = strtok(query_copy, " \t");
    while (keyword != NULL) {
        if (strlen(keyword) > 2) {
            for (char *cursor = keyword; *cursor != '\0'; cursor++) {
                *cursor = (char)tolower((unsigned char)*cursor);
            }
            if (strstr(lowered_path, keyword) != NULL) {
                score += 15;
            }
            if (strcasestr(content, keyword) != NULL) {
                score += 8;
            }
        }
        keyword = strtok(NULL, " \t");
    }
    if (strlen(content) > 15000) {
        score -= 10;
    }
    if (score < 0) {
        score = 0;
    }
    if (score > 100) {
        score = 100;
    }
    return score;
}

static int control_word(const char *name) {
    static const char *words[] = {"if", "while", "for", "switch", "return", "sizeof", "catch", "else", NULL};
    for (int word_index = 0; words[word_index] != NULL; word_index++) {
        if (strcmp(name, words[word_index]) == 0) {
            return 1;
        }
    }
    return 0;
}

enum { KEEP_TYPE_BODY = 0, DROP_FUNCTION_BODY = 1 };

static void copy_surface(const char *declaration, int drop_body, char *destination, size_t destination_size) {
    char buffer[MAX_DECLARATION];
    snprintf(buffer, sizeof buffer, "%s", declaration);
    if (drop_body) {
        char *brace = strchr(buffer, '{');
        if (brace != NULL) {
            *brace = '\0';
        }
    }
    size_t length = strlen(buffer);
    while (length > 0 && isspace((unsigned char)buffer[length - 1])) {
        buffer[--length] = '\0';
    }
    snprintf(destination, destination_size, "%s", buffer);
}

static void remember_signature(SourceFile *source_file, const char *signature) {
    if (source_file->signature_count >= MAX_SIGNATURES || signature[0] == '\0') {
        return;
    }
    snprintf(source_file->signatures[source_file->signature_count].text,
             sizeof source_file->signatures[0].text, "%s", signature);
    source_file->signature_count++;
}

static void take_purpose(const char *content, char *purpose, size_t purpose_size, const char *fallback) {
    snprintf(purpose, purpose_size, "%s", fallback);
    const char *cursor = content;
    while (*cursor != '\0') {
        const char *line_end = strchr(cursor, '\n');
        size_t line_length = line_end == NULL ? strlen(cursor) : (size_t)(line_end - cursor);
        while (line_length > 0 && isspace((unsigned char)cursor[0])) {
            cursor++;
            line_length--;
        }
        if (line_length > 2 && (strncmp(cursor, "//", 2) == 0 || strncmp(cursor, "/*", 2) == 0 || cursor[0] == '*')) {
            char line_buffer[160];
            size_t copy_length = line_length < sizeof line_buffer - 1 ? line_length : sizeof line_buffer - 1;
            memcpy(line_buffer, cursor, copy_length);
            line_buffer[copy_length] = '\0';
            char *text = line_buffer;
            while (*text == '/' || *text == '*' || isspace((unsigned char)*text)) {
                text++;
            }
            char *tail = text + strlen(text);
            while (tail > text && (tail[-1] == '/' || tail[-1] == '*' || isspace((unsigned char)tail[-1]))) {
                *--tail = '\0';
            }
            if (text[0] != '\0') {
                snprintf(purpose, purpose_size, "%s", text);
                return;
            }
        } else if (line_length > 0 && cursor[0] != '#') {
            return;
        }
        if (line_end == NULL) {
            return;
        }
        cursor = line_end + 1;
    }
}

static int starts_type(const char *declaration) {
    return strncmp(declaration, "struct ", 7) == 0 || strncmp(declaration, "enum ", 5) == 0 ||
           strncmp(declaration, "union ", 6) == 0 || strncmp(declaration, "class ", 6) == 0 ||
           strncmp(declaration, "typedef struct ", 15) == 0 || strncmp(declaration, "typedef enum ", 13) == 0 ||
           strncmp(declaration, "typedef union ", 14) == 0;
}

static int capture_function_name(const char *declaration, char *name, size_t name_size) {
    const char *paren = strchr(declaration, '(');
    if (paren == NULL || paren == declaration) {
        return 0;
    }
    const char *name_end = paren;
    while (name_end > declaration && isspace((unsigned char)name_end[-1])) {
        name_end--;
    }
    const char *name_start = name_end;
    while (name_start > declaration && (isalnum((unsigned char)name_start[-1]) || name_start[-1] == '_' || name_start[-1] == '~')) {
        name_start--;
    }
    if (name_start == name_end) {
        return 0;
    }
    size_t length = (size_t)(name_end - name_start);
    if (length >= name_size) {
        length = name_size - 1;
    }
    memcpy(name, name_start, length);
    name[length] = '\0';
    return 1;
}

static void extract_file(SourceFile *source_file, const char *content, const char *language_name) {
    char fallback[64];
    snprintf(fallback, sizeof fallback, "%s translation unit", language_name);
    take_purpose(content, source_file->purpose, sizeof source_file->purpose, fallback);
    const char *cursor = content;
    char pending[MAX_DECLARATION];
    pending[0] = '\0';
    while (*cursor != '\0' && source_file->signature_count < MAX_SIGNATURES) {
        const char *line_end = strchr(cursor, '\n');
        size_t line_length = line_end == NULL ? strlen(cursor) : (size_t)(line_end - cursor);
        char raw_line[MAX_LINE];
        size_t copy_length = line_length < sizeof raw_line - 1 ? line_length : sizeof raw_line - 1;
        memcpy(raw_line, cursor, copy_length);
        raw_line[copy_length] = '\0';
        char *stripped = raw_line;
        while (*stripped != '\0' && isspace((unsigned char)*stripped)) {
            stripped++;
        }
        int skip_line = stripped[0] == '\0' || stripped[0] == '#' || strncmp(stripped, "//", 2) == 0 ||
                        strncmp(stripped, "/*", 2) == 0 || stripped[0] == '*';
        if (pending[0] == '\0' && skip_line) {
            cursor = line_end == NULL ? cursor + line_length : line_end + 1;
            continue;
        }
        if (pending[0] == '\0') {
            size_t copy_count = strlen(stripped);
            if (copy_count >= sizeof pending) {
                copy_count = sizeof pending - 1;
            }
            memcpy(pending, stripped, copy_count);
            pending[copy_count] = '\0';
        } else if (strlen(pending) + strlen(stripped) + 2 < sizeof pending) {
            strcat(pending, " ");
            strcat(pending, stripped);
        }
        size_t pending_length = strlen(pending);
        int complete = pending_length > 0 && (pending[pending_length - 1] == '{' || pending[pending_length - 1] == ';' ||
                                              pending[pending_length - 1] == '}' || pending_length > 380);
        if (complete) {
            char surface[MAX_LINE];
            char function_name[128];
            int is_function = strchr(pending, '(') != NULL &&
                              capture_function_name(pending, function_name, sizeof function_name) &&
                              !control_word(function_name);
            if (is_function) {
                copy_surface(pending, DROP_FUNCTION_BODY, surface, sizeof surface);
                remember_signature(source_file, surface);
            } else if (starts_type(pending)) {
                copy_surface(pending, KEEP_TYPE_BODY, surface, sizeof surface);
                remember_signature(source_file, surface);
            }
            pending[0] = '\0';
        }
        if (line_end == NULL) {
            break;
        }
        cursor = line_end + 1;
    }
}

static int compare_relevance(const void *left_item, const void *right_item) {
    const SourceFile *left_file = left_item;
    const SourceFile *right_file = right_item;
    return right_file->relevance - left_file->relevance;
}

static void consider_file(const char *absolute_path) {
    char language_name[8];
    if (!extension_language(absolute_path, language_name, sizeof language_name)) {
        return;
    }
    if (!language_selected(language_name) || path_is_skipped(absolute_path)) {
        return;
    }
    FILE *source = fopen(absolute_path, "r");
    if (source == NULL) {
        return;
    }
    char *content = malloc(MAX_FILE_BYTES + 1);
    if (content == NULL) {
        fclose(source);
        return;
    }
    size_t bytes_read = fread(content, 1, MAX_FILE_BYTES, source);
    content[bytes_read] = '\0';
    fclose(source);
    if (candidate_count >= MAX_CANDIDATES) {
        free(content);
        return;
    }
    SourceFile *source_file = &candidates[candidate_count];
    memset(source_file, 0, sizeof *source_file);
    const char *relative = absolute_path;
    size_t root_length = strlen(project_root);
    if (strncmp(absolute_path, project_root, root_length) == 0) {
        relative = absolute_path + root_length;
        if (*relative == '/') {
            relative++;
        }
    }
    snprintf(source_file->relative_path, sizeof source_file->relative_path, "%s", relative);
    source_file->relevance = score_source(absolute_path, content);
    extract_file(source_file, content, language_name);
    candidate_count++;
    free(content);
}

static void walk_directory(const char *directory_path) {
    if (path_is_skipped(directory_path)) {
        return;
    }
    DIR *directory = opendir(directory_path);
    if (directory == NULL) {
        return;
    }
    struct dirent *entry;
    while ((entry = readdir(directory)) != NULL) {
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }
        char child_path[MAX_PATH];
        snprintf(child_path, sizeof child_path, "%s/%s", directory_path, entry->d_name);
        struct stat child_stat;
        if (stat(child_path, &child_stat) != 0) {
            continue;
        }
        if (S_ISDIR(child_stat.st_mode)) {
            walk_directory(child_path);
        } else if (S_ISREG(child_stat.st_mode)) {
            consider_file(child_path);
        }
    }
    closedir(directory);
}

static void print_usage(void) {
    fprintf(stderr, "usage: context-sage-c --project DIR --query TEXT [--lang c|cpp|all]\n");
}

int main(int argc, char **argv) {
    snprintf(language_filter, sizeof language_filter, "all");
    for (int argument_index = 1; argument_index < argc; argument_index++) {
        if (strcmp(argv[argument_index], "--project") == 0 && argument_index + 1 < argc) {
            snprintf(project_root, sizeof project_root, "%s", argv[++argument_index]);
        } else if (strcmp(argv[argument_index], "--query") == 0 && argument_index + 1 < argc) {
            snprintf(query_text, sizeof query_text, "%s", argv[++argument_index]);
        } else if (strcmp(argv[argument_index], "--lang") == 0 && argument_index + 1 < argc) {
            snprintf(language_filter, sizeof language_filter, "%s", argv[++argument_index]);
        } else {
            print_usage();
            return 2;
        }
    }
    if (project_root[0] == '\0' || query_text[0] == '\0') {
        print_usage();
        return 2;
    }
    if (strcmp(language_filter, "c++") == 0) {
        snprintf(language_filter, sizeof language_filter, "cpp");
    }
    walk_directory(project_root);
    qsort(candidates, (size_t)candidate_count, sizeof candidates[0], compare_relevance);
    for (int file_index = 0; file_index < candidate_count; file_index++) {
        SourceFile *source_file = &candidates[file_index];
        printf("FILE\t%s\t%d\t%s\n", source_file->relative_path, source_file->relevance, source_file->purpose);
        for (int signature_index = 0; signature_index < source_file->signature_count; signature_index++) {
            printf("SIG\t%s\n", source_file->signatures[signature_index].text);
        }
        printf("END\n");
    }
    return 0;
}
