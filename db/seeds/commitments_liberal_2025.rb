require 'json'

jsonl_path = File.expand_path('../commitments_liberal_2025.jsonl', __FILE__)
commitment_lines = File.readlines(jsonl_path).map(&:strip).reject(&:empty?)

puts "Loading #{commitment_lines.size} commitments from Liberal Platform 2025..."

government = Government.find_by!(slug: "federal")

source = Source.find_or_create_by!(
  government: government,
  title: "Liberal Platform 2025 - Canada Strong",
  source_type: :platform_document
) do |s|
  s.url = "https://liberal.ca/canada-strong/"
  s.date = Date.new(2025, 4, 1)
end

policy_areas = PolicyArea.all.index_by(&:slug)
departments = Department.all.index_by(&:slug)

# First pass: create all commitments
title_to_commitment = {}
parent_refs = {}

commitment_lines.each do |line|
  data = JSON.parse(line)
  next if data['title'].blank? || data['description'].blank? || data['commitment_type'].blank?

  commitment = Commitment.find_or_create_by!(
    government: government,
    title: data['title']
  ) do |c|
    c.description = data['description']
    c.original_text = data['original_text']
    c.commitment_type = data['commitment_type']
    c.status = :not_started
    c.policy_area = policy_areas[data['policy_area_slug']]
    c.party_code = data['party_code']
    c.region_code = data['region_code']
    c.date_promised = Date.new(2025, 4, 1)
  end

  title_to_commitment[data['title']] = commitment

  if data['parent_title'].present?
    parent_refs[data['title']] = data['parent_title']
  end

  CommitmentSource.find_or_create_by!(
    commitment: commitment,
    source: source
  ) do |cs|
    cs.section = data['source_section']
    cs.reference = data['source_reference']
    cs.excerpt = data['original_text']&.truncate(500)
  end

  (data['department_slugs'] || []).each do |dept_data|
    dept = departments[dept_data['slug']]
    next unless dept

    CommitmentDepartment.find_or_create_by!(
      commitment: commitment,
      department: dept
    ) do |cd|
      cd.is_lead = dept_data['is_lead'] || false
    end
  end
end

# Second pass: set parent references
parent_refs.each do |child_title, parent_title|
  child = title_to_commitment[child_title]
  parent = title_to_commitment[parent_title]
  next unless child && parent

  child.update!(parent: parent) unless child.parent_id == parent.id
end

puts "Done! Created #{title_to_commitment.size} commitments."
puts "  Types: #{Commitment.where(government: government).group(:commitment_type).count}"
