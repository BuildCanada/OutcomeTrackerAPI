#!/bin/bash
# Run commitment evaluations with a sliding window of 10 concurrent jobs.
# As soon as one finishes, the next one starts.
# Logs go to agent/logs/<commitment_id>.log

cd "$(dirname "$0")"

export AGENT_DATABASE_URL="${AGENT_DATABASE_URL:-postgresql://agent_reader:@localhost:5432/outcome_tracker_api_development}"
export RAILS_API_URL="${RAILS_API_URL:-http://localhost:3000}"
export RAILS_API_KEY="${RAILS_API_KEY:-agent-secret-key}"
export AGENT_MODEL="${AGENT_MODEL:-claude-sonnet-4-6}"

LOGDIR="$(pwd)/logs"
mkdir -p "$LOGDIR"

IDS=(2467 2534 2536 2538 2543 2546 2560 2563 2565 2567 2568 2569 2571 2572 2574 2576 2577 2578 2581 2582 2584 2585 2586 2588 2590 2591 2593 2595 2598 2600 2601 2602 2603 2610 2616 2623 2624 2625 2631 2635 2636 2637 2638 2639 2641 2642 2643 2644 2645 2647 2648 2649 2650 2651 2652 2654 2655 2659 2660 2661 2662 2663 2665 2666 2667 2668 2669 2670 2671 2672 2673 2674 2675 2677 2678 2679 2680 2681 2682 2683 2684 2685 2686 2687 2688 2689 2690 2691 2692 2693 2694 2695 2698 2700 2701 2702 2703 2704 2705 2706 2707 2708 2711 2712 2713 2714 2715 2716 2717 2719 2720 2721 2722 2723 2724 2726 2727 2728 2729 2730 2731 2732 2733 2734 2735 2736 2737 2738 2739 2740 2742 2743 2745 2747 2749 2752 2753 2754 2755 2756 2757 2758 2759 2760 2761 2762 2764 2765 2767 2768 2770 2771 2772 2776 2778 2781 2783 2787 2790 2791 2792 2793 2794 2795 2796 2797 2798 2800 2801 2802 2803 2804 2806 2807 2808 2810 2811 2812 2813 2816 2819 2822 2823 2825 2827 2828 2829 2832 2833 2834 2835 2839 2840 2841 2843 2895 2896 2898 2901 2902 2906 2909 2910 2911 2912 2913 2919 2922 2925 2926 2929 2930 2933 2938 2939 2941 2942 2943 2944 2945 2947 2949 2950 2951 2957 2959 2960 2962 2963 2964 2965 2966 2969 2972 2978 2981 2986 2994 2995 2996 2997 2998 3000 3001 3003 3004 3005 3008 3009 3010 3011 3012 3013 3014 3015 3016 3018 3020 3021 3022 3023 3025 3026 3027 3028 3029 3030 3031 3032 3035 3036 3038 3039 3040 3041 3042 3043 3044 3045 3047 3048 3049 3050 3051 3052 3053 3054 3055 3056 3057 3060 3061 3062 3063 3064 3065 3066 3067 3069 3076 3077 3078 3081 3084 3085 3086 3087 3088 3091 3095 3096 3099 3100 3101 3105 3108 3109 3110 3111 3112 3118 3122 3124 3125 3126 3128 3129 3131 3134 3137 3140 3141 3143 3150 3151 3152 3153 3155 3156 3157 3158 3160 3161 3165 3168 3176 3177 3178 3179 3180 3181 3182 3183 3186 3188 3190 3191 3192 3193 3194 3198 3201 3203 3204 3206 3207 3209 3213 3214 3217 3219 3220 3221 3223 3224 3228 3230 3236 3242 3243 3257 3258 3260 3264 3266 3269 3273 3278 3283 3284 3285 3286 3289 3307 3310 3311 3317 3323)

MAX_CONCURRENT=50
TOTAL=${#IDS[@]}
SUCCESS=0
FAIL=0
LAUNCHED=0
FAILED_IDS=()

# Map: PID -> commitment ID
declare -A PID_TO_CID

echo "Starting evaluation of $TOTAL commitments, sliding window of $MAX_CONCURRENT"
echo "Logs: $LOGDIR/<commitment_id>.log"
echo "Started at: $(date)"
echo ""

# Launch a single commitment evaluation in background
launch() {
  local CID=$1
  python -m agent.main evaluate --commitment-id "$CID" > "$LOGDIR/${CID}.log" 2>&1 &
  local PID=$!
  PID_TO_CID[$PID]=$CID
  LAUNCHED=$((LAUNCHED + 1))
  echo "[$(date +%H:%M:%S)] Started commitment $CID (pid $PID) [$LAUNCHED/$TOTAL launched]"
}

# Wait for any one child to finish, handle result, return
wait_one() {
  while true; do
    for PID in "${!PID_TO_CID[@]}"; do
      if ! kill -0 "$PID" 2>/dev/null; then
        # Process finished, get exit code
        wait "$PID" 2>/dev/null
        local EXIT=$?
        local CID=${PID_TO_CID[$PID]}
        unset "PID_TO_CID[$PID]"

        if [ $EXIT -eq 0 ]; then
          SUCCESS=$((SUCCESS + 1))
          echo "[$(date +%H:%M:%S)] ✓ Commitment $CID succeeded ($SUCCESS ok, $FAIL failed, $((TOTAL - SUCCESS - FAIL)) remaining)"
        else
          FAIL=$((FAIL + 1))
          FAILED_IDS+=($CID)
          echo "[$(date +%H:%M:%S)] ✗ Commitment $CID FAILED (exit $EXIT) — see $LOGDIR/${CID}.log"
        fi
        return
      fi
    done
    sleep 1
  done
}

# Fill initial window
for ((i=0; i<MAX_CONCURRENT && i<TOTAL; i++)); do
  launch "${IDS[$i]}"
done

# Sliding window: as each finishes, launch next
NEXT_IDX=$MAX_CONCURRENT
while [ ${#PID_TO_CID[@]} -gt 0 ]; do
  wait_one
  if [ $NEXT_IDX -lt $TOTAL ]; then
    launch "${IDS[$NEXT_IDX]}"
    NEXT_IDX=$((NEXT_IDX + 1))
  fi
done

echo ""
echo "=== COMPLETE ==="
echo "Finished at: $(date)"
echo "Success: $SUCCESS / $TOTAL"
echo "Failed: $FAIL"
if [ ${#FAILED_IDS[@]} -gt 0 ]; then
  echo "Failed IDs: ${FAILED_IDS[*]}"
fi
