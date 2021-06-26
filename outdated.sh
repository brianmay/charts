#!/bin/bash
set -e

helm repo update

for chart in charts/*; do
    test -f "$chart/Chart.yaml" || continue

    helm dependency update --skip-refresh --verify "$chart" > /dev/null

    while IFS= read -r dependency; do
        test -n "$dependency" || continue

        subchart="$(echo "$dependency" | awk '{print $1}')"
        current="$(echo "$dependency" | awk '{print $2}')"
        repo="$(echo "$dependency" | awk '{print $3}')"
        latest=$(helm inspect chart --repo "$repo" "$subchart" | yq e '.version' -)

        if [ "$current" == "$latest" ]; then
            true
        else
            printf "%s: Consider upgrading %s: %s -> %s.\\n" \
                "$chart" "$subchart" "$current" "$latest"
        fi
    done < <(helm dep list "$chart" | tail -n +2)
done
