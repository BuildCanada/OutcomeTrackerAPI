namespace :dedup do
  # Cross-group duplicates that differ in title/policy-area and can't be caught
  # by the word-overlap algorithm. Discovered via manual review of Budget 2025
  # extraction results.
  CROSS_GROUP_MERGES = [
    # === Previously merged (kept for idempotency — skipped if IDs no longer active) ===
    [ 2851, 3234, 2901, 3298 ],
    [ 2655, 2746, 2977, 2868, 3251 ],
    [ 2869, 3252, 2918, 3313 ],
    [ 2399, 2936 ],
    [ 2495, 3017, 2932, 2940, 3274 ],
    [ 2859, 2909, 3241, 3305 ],

    # === Finance ===
    [ 2509, 2555 ],             # SR&ED claimable amount $6M
    [ 2514, 2560 ],             # 20% AI Deployment Tax Credit for SMEs
    [ 2567, 2587 ],             # Labour Mobility Tax Deduction skilled trades
    [ 2569, 2606 ],             # $150B private sector investment
    [ 2469, 2574 ],             # GST cut first-time homebuyers
    [ 2528, 2592 ],             # Special Import Measures Act modernization
    [ 2530, 2594 ],             # Debt-to-GDP declining
    [ 2536, 2599 ],             # Separation of capital and operating spending
    [ 2486, 2544 ],             # Critical Mineral Exploration Tax Credit expansion
    [ 2548, 2657, 2979 ],       # Sustainable Investment Guidelines
    [ 2549, 2980 ],             # Sustainable Bond Framework
    [ 2793, 3189 ],             # Immediate expensing manufacturing buildings
    [ 2646, 2969 ],             # Carbon contracts for difference via CGF
    [ 2652, 2974 ],             # Crown corp Clean Electricity ITC eligibility
    [ 2654, 2976 ],             # Domestic content requirements clean economy
    [ 2666, 2988, 3265 ],       # Prohibit investment account transfer fees
    [ 2667, 2989 ],             # Timely transfer of registered accounts
    [ 2668, 2990 ],             # Cross-border transfer fee transparency
    [ 2670, 2991, 3267 ],       # Credit union scaling and federal entry
    [ 2720, 2805, 3197, 3281 ], # Underused Housing Tax elimination
    [ 2839, 2892, 3222, 3292 ], # Finance officials civil liability protection
    [ 2843, 3226 ],             # Third-party cash deposits restriction
    [ 2844, 3227 ],             # Public-private info sharing AML
    [ 2846, 3229 ],             # PCMLTFA regulatory authority
    [ 2848, 3231 ],             # PCMLTFA all financial donations
    [ 2849, 2897, 3296 ],       # AML supervision and penalties
    [ 2852, 2903, 3299 ],       # Insured mortgage protected limit $500B
    [ 2853, 2904, 3300 ],       # Borrowing Authority Act limit increase
    [ 2855, 2906, 3237, 3302 ], # Duty drawback charitable donations
    [ 2867, 3250, 3312 ],       # Canada Development Investment Corporation
    [ 2886, 2993, 3270 ],       # Consumer-driven banking framework
    [ 2831, 3214, 3287 ],       # Electronic notice-and-access financial governance
    [ 2832, 3215, 3288 ],       # Bearer form instruments prohibition
    [ 2809, 2928, 2929, 3184, 3322 ], # Qualified investment rules registered plans
    [ 2799, 2815, 3070, 3173, 3193 ], # Tiered corporate structures tax deferral
    [ 2808, 2817, 2931, 3196, 3324 ], # GST/HST osteopathic services
    [ 2819, 2820, 2821, 3199 ], # Luxury tax aircraft/vessels
    [ 2822, 3200 ],             # 2026-27 borrowing plan update
    [ 2823, 3079, 3202 ],       # Canada Mortgage Bonds $30B purchases
    [ 2895, 3295 ],             # AML technical amendments
    [ 2790, 3164 ],             # Medical Expense/Home Accessibility dual claim
    [ 2792, 3166 ],             # Carbon Rebate post-October 2026
    [ 2804, 3071 ],             # FAPI foreign affiliate investment income
    [ 2800, 3174 ],             # Exploration expense economic viability studies
    [ 2798, 3172 ],             # CGF financing Clean Electricity ITC cost base
    [ 3219, 3290 ],             # OSFI integrity and security authorities
    [ 3221, 3291 ],             # Retail Payment Act confidentiality
    [ 3035, 3275 ],             # Economic abuse code of conduct
    [ 2724, 3080 ],             # Early learning childcare transfers 3%
    [ 2998, 2999, 3271 ],       # Stablecoin regulation
    [ 2593, 2946 ],             # Declining deficit trajectory
    [ 2814, 3192 ],             # Clean Electricity ITC legislation
    [ 2833, 2889, 3216 ],       # Bank branch closure public notice
    [ 2835, 2890, 3218 ],       # Digital ID verification bank account opening
    [ 2841, 2894, 3294 ],       # Minister of Finance consultation sanctions
    [ 2810, 3163, 3185 ],       # CRA/ESDC info sharing worker misclassification

    # === Defence ===
    [ 2385, 2543 ],             # NATO 2% GDP spending target
    [ 2541, 2602 ],             # $30.9B defence spending over four years
    [ 2773, 3140 ],             # Retire obsolete CAF fleets
    [ 2774, 3141 ],             # Divest surplus DND property
    [ 2775, 3142 ],             # Energy Performance Contracts defence
    [ 2942, 3046 ],             # Defence Industrial Strategy

    # === Transport ===
    [ 2357, 2575 ],             # High-speed rail Windsor-Quebec
    [ 3236, 3282 ],             # Alto HSR legislation accelerate
    [ 2637, 2954 ],             # Airport lease extensions
    [ 2638, 2955 ],             # Airport privatization options
    [ 2639, 2956, 3263 ],       # Airport safety infrastructure $55.2M
    [ 2865, 3248, 3310 ],       # Aeronautics Act aviation safety
    [ 2866, 3249, 3311 ],       # Temporary orders international transport standards
    [ 3008, 3154 ],             # $5B Trade Diversification Corridors Fund

    # === Environment ===
    [ 2650, 2971 ],             # EV Availability Standard 2026 target
    [ 2676, 2972 ],             # Clean Fuel Regulations biofuels
    [ 2661, 2983 ],             # Climate Competitiveness Strategy metrics
    [ 2717, 3075 ],             # Output-Based Pricing System maintenance
    [ 2647, 2973 ],             # CEPA clean electricity agreements
    [ 3005, 3272 ],             # Landfill methane regulations funding

    # === CRA ===
    [ 2690, 3007 ],             # Corporate tax/GST deferral liquidity
    [ 2718, 2732 ],             # Wind down CRA fuel charge/DST units

    # === Jobs and Families ===
    [ 2682, 3006 ],             # $570M LMDA tariff-impacted workers
    [ 2565, 3019, 3102 ],       # Union Training and Innovation Program
    [ 2521, 2566 ],             # $20M college apprenticeship training
    [ 2742, 3103 ],             # Foreign Credential Recognition Fund
    [ 2913, 3245, 3308 ],       # Government Annuities audit elimination
    [ 3069, 2884 ],             # Student grants/loans public institutions only

    # === Housing & Infrastructure ===
    [ 2642, 2961 ],             # $6B Direct Delivery infrastructure stream
    [ 2759, 2948 ],             # Build Communities Strong Fund
    [ 2495, 3205, 3259 ],       # Build Canada Homes establishment

    # === Industry ===
    [ 2513, 2559 ],             # Black Entrepreneurship Program permanent
    [ 2662, 2984 ],             # Dig once policy fibre optic
    [ 2664, 2986 ],             # Spectrum Licence Transfer Framework
    [ 2767, 3135 ],             # Net Zero Accelerator wind down
    [ 2769, 3137 ],             # Statistics Canada data collection frequency
    [ 2921, 3317 ],             # Predatory debt advisors penalties
    [ 2952, 3160 ],             # Granting council 2% savings
    [ 2660, 2880, 2982 ],       # Competition Act greenwashing provisions

    # === Global Affairs ===
    [ 2525, 2589 ],             # $25B export credit facility
    [ 2526, 2590 ],             # CanExport program diversification
    [ 2527, 2591 ],             # MERCOSUR/ASEAN trade agreements
    [ 2534, 2597 ],             # OECD global tax rules leadership
    [ 2752, 3113, 3114 ],       # Embassy consolidation/co-location
    [ 2856, 2905, 3238, 3301 ], # Export and Import Permits Act security
    [ 2893, 3223, 3293 ],       # Windfall profit charge sanctions
    [ 2824, 3207 ],             # IDRC Board reduction

    # === Heritage ===
    [ 2518, 2563 ],             # E-book accessibility 2030
    [ 2696, 2864 ],             # Artist's Resale Right
    [ 2875, 2924, 3319 ],       # Broadcasting Act privacy rights
    [ 3032, 3261, 3277 ],       # CBC/Radio-Canada funding
    [ 2377, 3089 ],             # Canada Strong Pass 2025
    [ 2739, 3097 ],             # Heritage digital platform

    # === Health ===
    [ 2753, 3120 ],             # CFIA lab consolidation
    [ 2754, 3115 ],             # CFIA pet export digital
    [ 2755, 3116 ],             # CFIA vehicle washing stations
    [ 2756, 3117 ],             # CFIA food grading dispute resolution
    [ 2758, 3121 ],             # PHAC grants consolidation

    # === Public Safety ===
    [ 2713, 3058 ],             # $1.76B law enforcement
    [ 2714, 3059 ],             # $834M CBSA enhancement
    [ 2781, 3146 ],             # $617.7M CBSA operations
    [ 2783, 3037, 3148 ],       # 1000 RCMP personnel
    [ 2778, 3144 ],             # Resilience Centre discontinue
    [ 2780, 3145 ],             # CBSA fleet lifecycle 10 years
    [ 2784, 3149 ],             # RCMP cannabis reimbursement $6

    # === Gov Transformation ===
    [ 2788, 3152 ],             # AI chatbots PSPC
    [ 2789, 3151 ],             # Redundant software/fixed lines
    [ 3053, 3279 ],             # Industrial Security Program

    # === Treasury Board ===
    [ 2825, 3208 ],             # Early Retirement Incentive Program
    [ 2827, 3210 ],             # 2% pension benefit rate
    [ 2828, 3211 ],             # Legislative amendments efficiency
    [ 2871, 2920, 3254, 3315 ], # Regulatory sandboxes

    # === Other Ministries ===
    [ 2422, 2442 ],             # National School Food Program Canadian food
    [ 2857, 2907 ],             # FNFA lending to Indigenous SPVs
    [ 2585, 2622 ],             # GBA+ analysis all measures
    [ 2704, 3159 ],             # WAGE department funding
    [ 2488, 2547 ],             # EV charging stations 2027
    [ 2656, 2978 ],             # $50M Critical Minerals admin
    [ 2744, 3105 ],             # Greener Homes Grant wind down
    [ 2745, 3106 ],             # 2 Billion Trees end
    [ 2870, 2919, 3253 ],       # LNG export licence 50 years
    [ 2763, 3131 ],             # Settlement Program eligibility limits
    [ 2434, 2937 ],             # Bail/sentencing stricter
    [ 2771, 3138 ],             # Tax Court informal procedure limits
    [ 2772, 3139 ],             # CHRC commissioner consolidation
    [ 2910, 3306 ],             # Tribunal administrative support
    [ 2750, 3110 ]             # Self-assessment small DFO projects
  ].freeze

  SIMILARITY_THRESHOLD = 0.80

  desc "Find duplicate commitments (dry-run, no changes)"
  task find: :environment do
    groups = find_duplicate_groups
    print_report(groups)
  end

  desc "Merge duplicate commitments"
  task merge: :environment do
    groups = find_duplicate_groups

    if groups.empty?
      puts "No duplicates found."
      next
    end

    print_report(groups)

    total_merges = groups.sum { |g| g[:ids].size - 1 }
    before_count = Commitment.where.not(status: :abandoned).count
    puts "\n#{"=" * 60}"
    puts "About to merge #{total_merges} commitments across #{groups.size} groups."
    puts "Active commitments before: #{before_count}"
    puts "Expected after: #{before_count - total_merges}"
    puts "#{"=" * 60}\n"

    merged = 0
    ActiveRecord::Base.transaction do
      groups.each do |group|
        keep = select_keeper(group[:ids])
        duplicates = group[:ids] - [ keep.id ]

        duplicates.each do |dup_id|
          dup_commitment = Commitment.find(dup_id)
          merge_commitment(keep, dup_commitment, group[:reason])
          merged += 1
          puts "  Merged ##{dup_id} -> ##{keep.id}"
        end
      end
    end

    after_count = Commitment.where.not(status: :abandoned).count
    puts "\nDone. Merged #{merged} commitments."
    puts "Active commitments: #{before_count} -> #{after_count}"
  end

  private

  def find_duplicate_groups
    commitments = Commitment.where.not(status: :abandoned)
      .includes(:commitment_sources, :criteria, :policy_area)
      .order(:id)

    groups = []
    seen = Set.new

    # Phase 1: Cross-group merges (hard-coded known duplicates)
    CROSS_GROUP_MERGES.each do |ids|
      active_ids = ids.select { |id| commitments.any? { |c| c.id == id } }
      next if active_ids.size < 2

      seen.merge(active_ids)
      titles = active_ids.map { |id| commitments.find { |c| c.id == id }&.title }.compact
      groups << {
        ids: active_ids,
        reason: "Cross-group duplicate (manually identified)",
        titles: titles
      }
    end

    # Phase 2: Word-overlap within same policy area
    commitments.group_by(&:policy_area_id).each do |policy_area_id, batch|
      next if batch.size < 2

      batch.combination(2).each do |a, b|
        next if seen.include?(a.id) && seen.include?(b.id)

        similarity = word_overlap(a.title, b.title)
        next if similarity < SIMILARITY_THRESHOLD

        # Find or create a group containing either commitment
        existing_group = groups.find do |g|
          g[:ids].include?(a.id) || g[:ids].include?(b.id)
        end

        if existing_group
          existing_group[:ids] |= [ a.id, b.id ]
          existing_group[:titles] |= [ a.title, b.title ]
        else
          groups << {
            ids: [ a.id, b.id ],
            reason: "Title similarity #{(similarity * 100).round(0)}% in same policy area",
            titles: [ a.title, b.title ]
          }
        end

        seen.add(a.id)
        seen.add(b.id)
      end
    end

    groups.select { |g| g[:ids].size >= 2 }
  end

  def word_overlap(title_a, title_b)
    words_a = normalize_words(title_a)
    words_b = normalize_words(title_b)
    return 0.0 if words_a.empty? || words_b.empty?

    intersection = words_a & words_b
    union = words_a | words_b
    intersection.size.to_f / union.size
  end

  def normalize_words(title)
    title.downcase.gsub(/[^a-z0-9\s]/, "").split.reject { |w| w.size < 3 }
  end

  def select_keeper(ids)
    candidates = Commitment.where(id: ids)
      .includes(:commitment_sources, :criteria)

    candidates.max_by do |c|
      [ c.commitment_sources.size, c.criteria.size, -c.id ]
    end
  end

  def merge_commitment(keep, duplicate, reason)
    Rails.logger.info("dedup:merge — Merging ##{duplicate.id} into ##{keep.id}: #{reason}")

    # Sources: delete overlapping, reassign rest
    duplicate.commitment_sources
      .where.not(source_id: keep.commitment_sources.select(:source_id))
      .update_all(commitment_id: keep.id)
    duplicate.commitment_sources.delete_all

    duplicate.criteria.update_all(commitment_id: keep.id)

    # Matches: composite unique on (commitment_id, matchable_type, matchable_id)
    # Delete where keep already has same (matchable_type, matchable_id), reassign rest
    CommitmentMatch.where(commitment_id: duplicate.id).where(
      "EXISTS (SELECT 1 FROM commitment_matches km WHERE km.commitment_id = ? " \
      "AND km.matchable_type = commitment_matches.matchable_type " \
      "AND km.matchable_id = commitment_matches.matchable_id)", keep.id
    ).delete_all
    duplicate.commitment_matches.update_all(commitment_id: keep.id)

    duplicate.events.update_all(commitment_id: keep.id)

    # Departments: delete overlapping, reassign rest
    duplicate.commitment_departments
      .where.not(department_id: keep.commitment_departments.select(:department_id))
      .update_all(commitment_id: keep.id)
    duplicate.commitment_departments.delete_all

    duplicate.destroy!
  end

  def print_report(groups)
    if groups.empty?
      puts "No duplicates found."
      return
    end

    total_merges = groups.sum { |g| g[:ids].size - 1 }
    puts "Found #{groups.size} duplicate groups (#{total_merges} merges needed)\n\n"

    groups.each_with_index do |group, i|
      puts "Group #{i + 1}: #{group[:ids].join(", ")} (keep #{select_keeper(group[:ids]).id})"
      puts "  Reason: #{group[:reason]}"
      group[:titles].each { |t| puts "  - #{t}" }
      puts
    end
  end
end
