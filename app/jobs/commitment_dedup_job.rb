class CommitmentDedupJob < ApplicationJob
  queue_as :default

  def perform(government)
    commitments = government.commitments.includes(:lead_department).where.not(status: :abandoned).order(:id)
    return if commitments.size < 2

    Rails.logger.info("CommitmentDedupJob: Checking #{commitments.size} commitments for duplicates")

    commitments.group_by(&:lead_department).each do |department, batch|
      next if batch.size < 2

      Rails.logger.info("CommitmentDedupJob: Checking #{batch.size} commitments for #{department&.display_name || 'unassigned'}")

      finder = CommitmentDedupFinder.create!(record: government)
      finder.extract!(finder.prompt(batch))

      (finder.duplicate_groups || []).each do |group|
        keep = Commitment.find_by(id: group["keep_id"])
        next unless keep

        merge_ids = Array(group["merge_ids"]).map(&:to_i) - [ keep.id ]
        duplicates = Commitment.where(id: merge_ids)

        duplicates.each do |dup_commitment|
          merge_commitment(keep, dup_commitment, group["reason"])
        end
      end
    end
  end

  private

  def merge_commitment(keep, duplicate, reason)
    Rails.logger.info("CommitmentDedupJob: Merging ##{duplicate.id} into ##{keep.id} — #{reason}")

    duplicate.commitment_sources.update_all(commitment_id: keep.id)
    duplicate.criteria.update_all(commitment_id: keep.id)
    duplicate.commitment_matches.update_all(commitment_id: keep.id)
    duplicate.events.update_all(commitment_id: keep.id)
    duplicate.commitment_departments.where.not(department_id: keep.commitment_departments.select(:department_id)).update_all(commitment_id: keep.id)
    duplicate.commitment_departments.where(department_id: keep.commitment_departments.select(:department_id)).delete_all

    duplicate.destroy!
  end
end
