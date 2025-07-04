class PromiseProgressUpdaterJob < ApplicationJob
    queue_as :default

    def perform(promise)
      promise.update_progress!(inline: true)
    end
end
