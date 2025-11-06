#!/bin/bash

printf "%-50s %-15s %s\n" "Pod Name" "Version" "Age"
printf "%-50s %-15s %s\n" "--------" "-------" "---"

kubectl get pods -o json | \
jq -r '.items[] | "\(.metadata.namespace) \(.metadata.name) \(.metadata.labels["app.kubernetes.io/version"] // "N/A") \(.metadata.creationTimestamp)"' | \
awk '{
    split($2, parts, "-")
    len = length(parts)
    base = ""
    for (i=1; i<=len-2; i++) {
        base = base (i>1 ? "-" : "") parts[i]
    }
    key = $1 "/" base
    if (!(key in seen)) {
        seen[key] = 1
        print $2, $3, $4
    }
}' | \
while read pod version timestamp; do
    age=$(( ($(date +%s) - $(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$timestamp" +%s 2>/dev/null || date -d "$timestamp" +%s 2>/dev/null)) ))
    days=$((age / 86400))
    hours=$(((age % 86400) / 3600))
    minutes=$(((age % 3600) / 60))
    seconds=$((age % 60))
    
    if [ $days -gt 0 ]; then
        age_str="${days}d${hours}h"
    elif [ $hours -gt 0 ]; then
        age_str="${hours}h${minutes}m"
    elif [ $minutes -gt 0 ]; then
        age_str="${minutes}m${seconds}s"
    else
        age_str="${seconds}s"
    fi
    printf "%-50s %-15s %s\n" "$pod" "$version" "$age_str"
done
