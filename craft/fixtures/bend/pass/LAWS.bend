import Base
import ./job.bend as Job
law cancel_queued:
  {Job.cancel(Job.Queued{}) == Job.Finished{} : Job.State}
