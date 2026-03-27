module Api
  module Agent
    class CommitmentsController < BaseController
      def index
        scope = Commitment.includes(:policy_area)

        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.joins(:policy_area).where(policy_areas: { slug: params[:policy_area] }) if params[:policy_area].present?
        scope = scope.where(commitment_type: params[:commitment_type]) if params[:commitment_type].present?
        if params[:government_id].present?
          scope = scope.where(government_id: params[:government_id])
        end
        if params[:stale_days].present?
          cutoff = params[:stale_days].to_i.days.ago
          scope = scope.where("last_assessed_at IS NULL OR last_assessed_at < ?", cutoff)
        end

        limit = (params[:limit] || 50).to_i
        offset = (params[:offset] || 0).to_i
        commitments = scope.order("last_assessed_at ASC NULLS FIRST, id ASC").limit(limit).offset(offset)

        render json: commitments.map { |c| serialize_commitment_summary(c) }
      end

      def show
        commitment = Commitment.find(params[:id])

        criteria = commitment.criteria.order(:category, :position).map do |cr|
          {
            id: cr.id, category: cr.category, description: cr.description,
            verification_method: cr.verification_method, status: cr.status,
            evidence_notes: cr.evidence_notes, assessed_at: cr.assessed_at, position: cr.position,
          }
        end

        matches = CommitmentMatch.includes(:matchable)
          .where(commitment_id: commitment.id)
          .order(relevance_score: :desc)
          .map do |m|
            matchable_title = m.matchable_type == "Bill" ? m.matchable&.bill_number_formatted : m.matchable&.title
            matchable_detail = m.matchable_type == "Bill" ? m.matchable&.short_title : m.matchable&.url
            {
              id: m.id, matchable_type: m.matchable_type, matchable_id: m.matchable_id,
              relevance_score: m.relevance_score, relevance_reasoning: m.relevance_reasoning,
              matched_at: m.matched_at, assessed: m.assessed,
              matchable_title: matchable_title, matchable_detail: matchable_detail,
            }
          end

        events = commitment.events.order(occurred_at: :desc).limit(50).map do |e|
          {
            id: e.id, event_type: e.event_type, action_type: e.action_type,
            title: e.title, description: e.description, occurred_at: e.occurred_at,
            metadata: e.metadata,
          }
        end

        sources = CommitmentSource.includes(:source)
          .where(commitment_id: commitment.id)
          .map do |cs|
            {
              id: cs.id, section: cs.section, reference: cs.reference,
              excerpt: cs.excerpt, relevance_note: cs.relevance_note,
              source_title: cs.source&.title, source_type: cs.source&.source_type,
              source_url: cs.source&.url, source_date: cs.source&.date,
            }
          end

        departments = CommitmentDepartment.includes(:department)
          .where(commitment_id: commitment.id)
          .order(is_lead: :desc)
          .map do |cd|
            {
              id: cd.department_id, slug: cd.department&.slug,
              display_name: cd.department&.display_name,
              official_name: cd.department&.official_name,
              is_lead: cd.is_lead,
            }
          end

        status_changes = CommitmentStatusChange.where(commitment_id: commitment.id)
          .order(changed_at: :desc).limit(10)
          .map do |sc|
            {
              previous_status: sc.previous_status, new_status: sc.new_status,
              changed_at: sc.changed_at, reason: sc.reason,
            }
          end

        render json: {
          id: commitment.id,
          title: commitment.title,
          description: commitment.description,
          original_text: commitment.original_text,
          commitment_type: commitment.commitment_type,
          status: commitment.status,
          date_promised: commitment.date_promised,
          target_date: commitment.target_date,
          last_assessed_at: commitment.last_assessed_at,
          government_id: commitment.government_id,
          policy_area_name: commitment.policy_area&.name,
          policy_area_slug: commitment.policy_area&.slug,
          criteria: criteria,
          matches: matches,
          events: events,
          sources: sources,
          departments: departments,
          status_changes: status_changes,
        }
      end

      def sources
        commitment = Commitment.find(params[:id])
        result = CommitmentSource.includes(:source)
          .where(commitment_id: commitment.id)
          .map do |cs|
            {
              section: cs.section, reference: cs.reference,
              excerpt: cs.excerpt, relevance_note: cs.relevance_note,
              title: cs.source&.title, source_type: cs.source&.source_type,
              url: cs.source&.url, date: cs.source&.date,
            }
          end
        render json: result
      end

      def touch_assessed
        commitment = Commitment.find(params[:id])
        reasoning = params[:reasoning].presence || "Session ended — last assessed timestamp updated"

        # Only update if the agent didn't already record an evaluation run this session
        # (record_evaluation_run also sets last_assessed_at, so skip the fallback if it was called)
        recent_run = EvaluationRun.where(commitment_id: commitment.id)
          .where("created_at > ?", 15.minutes.ago)
          .exists?

        if recent_run
          render json: { id: commitment.id, last_assessed_at: commitment.last_assessed_at, skipped: true, reason: "evaluation_run already recorded" }
          return
        end

        commitment.update!(last_assessed_at: Time.current)
        Rails.logger.info("AgentHook: Updated last_assessed_at for commitment #{commitment.id} — #{reasoning}")
        render json: { id: commitment.id, last_assessed_at: commitment.last_assessed_at, skipped: false }
      end

      private

      def serialize_commitment_summary(c)
        {
          id: c.id,
          title: c.title,
          description: c.description,
          commitment_type: c.commitment_type,
          status: c.status,
          target_date: c.target_date,
          date_promised: c.date_promised,
          last_assessed_at: c.last_assessed_at,
          policy_area_name: c.policy_area&.name,
          policy_area_slug: c.policy_area&.slug,
          criteria_count: c.criteria.size,
          matches_count: c.commitment_matches.size,
        }
      end

      public

      def status
        commitment = Commitment.find(params[:id])
        previous_status = commitment.status

        new_status = params.require(:new_status)
        reasoning = params.require(:reasoning)
        source_urls = params.require(:source_urls)
        effective_date = params.require(:effective_date)

        sources = Source.where(url: source_urls)
        if sources.empty?
          render json: { error: "No sources found for provided URLs. Fetch pages first using pages/fetch." }, status: :unprocessable_entity
          return
        end

        primary_source = sources.first

        # Set transient attributes used by the after_update callback
        commitment.status_change_source = primary_source
        commitment.status_changed_at = effective_date
        commitment.status_change_reason = reasoning

        commitment.update!(status: new_status)

        render json: {
          id: commitment.id,
          previous_status: previous_status,
          new_status: commitment.status,
          reasoning: reasoning,
          effective_date: effective_date,
          source_ids: sources.pluck(:id),
        }
      end
    end
  end
end
