view: funnel_diagnostics {
 extends: [funnel_explorer]

measure: step_1_dropoffs { type: number sql: ${sessions_step_1}-${sessions_step_2} ;;  }
measure: step_1_continuation { type: number sql: SAFE_DIVIDE(${sessions_step_2},${sessions_step_1}) ;; value_format_name: percent_2 }
measure: step_1_abandonment { type: number sql: SAFE_DIVIDE(${step_1_dropoffs},${sessions_step_1}) ;; value_format_name: percent_2 }
dimension: seconds_1_to_2 { type: number  sql: TIMESTAMP_DIFF(${step2_raw},${step1_raw},SECOND) ;; }
measure: median_seconds_1_to_2 { type: median sql: ${seconds_1_to_2} ;; value_format_name: decimal_1 }
measure: step_2_dropoffs { type: number sql: ${sessions_step_2}-${sessions_step_3} ;;  }
measure: step_2_continuation { type: number sql: SAFE_DIVIDE(${sessions_step_3},${sessions_step_2}) ;; value_format_name: percent_2 }
measure: step_2_abandonment { type: number sql: SAFE_DIVIDE(${step_2_dropoffs},${sessions_step_2}) ;; value_format_name: percent_2 }
dimension: seconds_2_to_3 { type: number  sql: TIMESTAMP_DIFF(${step3_raw},${step2_raw},SECOND) ;; }
measure: median_seconds_2_to_3 { type: median sql: ${seconds_2_to_3} ;; value_format_name: decimal_1 }
measure: step_3_dropoffs { type: number sql: ${sessions_step_3}-${sessions_step_4} ;;  }
measure: step_3_continuation { type: number sql: SAFE_DIVIDE(${sessions_step_4},${sessions_step_3}) ;; value_format_name: percent_2 }
measure: step_3_abandonment { type: number sql: SAFE_DIVIDE(${step_3_dropoffs},${sessions_step_3}) ;; value_format_name: percent_2 }
dimension: seconds_3_to_4 { type: number  sql: TIMESTAMP_DIFF(${step4_raw},${step3_raw},SECOND) ;; }
measure: median_seconds_3_to_4 { type: median sql: ${seconds_3_to_4} ;; value_format_name: decimal_1 }
dimension: seconds_to_complete { type: number  sql: TIMESTAMP_DIFF(${step4_raw},${step1_raw},SECOND) ;; }
measure: median_seconds_to_complete { type: median sql: ${seconds_to_complete} ;; value_format_name: decimal_1 }
}
