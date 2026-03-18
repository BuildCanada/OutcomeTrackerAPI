class MinisterDepartmentMapper < Chat
  include Structify::Model

  MODEL = "gemini-3.1-flash-lite-preview"

  after_create { with_model(MODEL, provider: :gemini, assume_exists: true) }

  schema_definition do
    version 1
    name "MinisterDepartmentMapper"
    description "Maps federal ministers to their responsible department(s)"
    field :mappings, :array,
      items: {
        type: "object",
        properties: {
          "person_id" => { type: "integer", description: "The person's ID from ourcommons.ca" },
          "department_slugs" => {
            type: "array",
            items: { type: "string" },
            description: "One or more department slugs this minister is responsible for"
          },
          "role" => {
            type: "string",
            enum: [ "Prime Minister", "Minister", "Secretary of State" ],
            description: "The minister's role type"
          }
        }
      }
  end

  def system_prompt
    "You are an expert on the Government of Canada's federal department structure. " \
    "You map ministers and secretaries of state to the federal departments they are responsible for."
  end

  def prompt(ministers_data, department_slugs)
    dept_list = department_slugs.map { |d| "  - #{d[:slug]}  (#{d[:official_name]})" }.join("\n")

    minister_list = ministers_data.map do |m|
      "  - person_id=#{m[:person_id]}: #{m[:first_name]} #{m[:last_name]} — #{m[:title]}"
    end.join("\n")

    <<~PROMPT
      Map each minister below to ONE or MORE department slugs from the provided list.

      AVAILABLE DEPARTMENTS:
      #{dept_list}

      CURRENT MINISTERS:
      #{minister_list}

      RULES:
      - The Prime Minister maps to "prime-minister-office"
      - A minister whose title covers multiple domains (e.g. "Minister of Finance and National Revenue") should map to BOTH relevant departments (e.g. "finance-canada" AND "canada-revenue-agency")
      - Secretaries of State should be mapped to the department that most closely aligns with their portfolio
      - "Minister of Internal Trade" maps to "transport-canada"
      - "Minister of Canadian Identity and Culture" maps to "canadian-heritage"
      - "Minister of Jobs and Families" maps to "employment-and-social-development-canada"
      - "Minister of Northern and Arctic Affairs" maps to "crown-indigenous-relations-and-northern-affairs-canada"
      - "Minister of the Environment, Climate Change and Nature" maps to "environment-and-climate-change-canada"
      - "Minister of Government Transformation, Public Works and Procurement" maps to "public-services-and-procurement-canada"
      - "Secretary of State (Sport)" maps to "canadian-heritage"
      - "Secretary of State (Children and Youth)" maps to "employment-and-social-development-canada"
      - "Secretary of State (Seniors)" maps to "employment-and-social-development-canada"
      - "Secretary of State (Labour)" maps to "employment-and-social-development-canada"
      - "Secretary of State (Defence Procurement)" maps to "national-defence"
      - "Secretary of State (Combatting Crime)" maps to "public-safety-canada"
      - "Secretary of State (International Development)" maps to "global-affairs-canada"
      - "Secretary of State (Canada Revenue Agency and Financial Institutions)" maps to "canada-revenue-agency"
      - "Secretary of State (Nature)" maps to "environment-and-climate-change-canada"
      - "Secretary of State (Rural Development)" maps to "rural-economic-development"
      - "Secretary of State (Small Business and Tourism)" maps to "innovation-science-and-economic-development-canada"
      - "President of the Treasury Board" is a "Minister" role, maps to "treasury-board-of-canada-secretariat"
      - "President of the King's Privy Council" is a "Minister" role, maps to "privy-council-office"
      - "Leader of the Government in the House of Commons" is a "Minister" role, maps to "privy-council-office"

      For role:
      - "Prime Minister" for the PM
      - "Minister" for full cabinet ministers (titled "Minister of X", "President of X", or "Leader of X")
      - "Secretary of State" for Secretaries of State

      Return a mapping for EVERY minister listed above. Use only slugs from the provided list.
    PROMPT
  end
end
