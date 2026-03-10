#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="../part1_capture"
mkdir -p "${OUT_DIR}"
rm -f "${OUT_DIR}"/*.json "${OUT_DIR}"/summary.txt "${OUT_DIR}"/elasticcommands.txt 2>/dev/null || true

cmd() {
  local title="$1"
  shift
  {
    echo "### ${title}"
    echo "$ $*"
    "$@"
    echo
  } >> "${OUT_DIR}/elasticcommands.txt"
}

json_cmd() {
  local file="$1"
  shift
  "$@" > "${OUT_DIR}/${file}"
}

# Section 1.1 (basic indexing flow)
cmd "Cluster health" curl -s "localhost:9200/_cat/health?v"
cmd "Node list" curl -s "localhost:9200/_cat/nodes?v"
cmd "Index list (before customer)" curl -s "localhost:9200/_cat/indices?v"
cmd "Create customer index" curl -s -XPUT "localhost:9200/customer?pretty"
cmd "Index list (after create customer)" curl -s "localhost:9200/_cat/indices?v"
cmd "Put customer doc id=1" curl -s -H "Content-Type: application/json" -XPUT "localhost:9200/customer/_doc/1?pretty" -d '{"name":"John Doe"}'
cmd "Get customer doc id=1" curl -s "localhost:9200/customer/_doc/1?pretty"
cmd "Delete customer index" curl -s -XDELETE "localhost:9200/customer?pretty"
cmd "Index list (after delete customer)" curl -s "localhost:9200/_cat/indices?v"

# Ensure no indices for Reddit section
curl -s -XDELETE "localhost:9200/comments,customer?ignore_unavailable=true" > /dev/null || true
cmd "Index list (after deleting all indices)" curl -s "localhost:9200/_cat/indices?v"

# Section 1.2 index Reddit
curl -s -H "Content-Type: application/json" -XPOST "localhost:9200/_bulk" --data-binary @test.json > /dev/null
cmd "Index list (after Reddit bulk index)" curl -s "localhost:9200/_cat/indices?v"

# Section 2 search outputs
json_cmd "query1_cat.json" curl -s -XGET "localhost:9200/_search?pretty" -H "Content-Type: application/json" -d '{ "query": { "match" : { "body" : { "query" : "cat"} } } }'
json_cmd "query2_cats.json" curl -s -XGET "localhost:9200/_search?pretty" -H "Content-Type: application/json" -d '{ "query": { "match" : { "body" : { "query" : "cats"} } } }'
json_cmd "query3_cat_cats_and.json" curl -s -XGET "localhost:9200/_search?pretty" -H "Content-Type: application/json" -d '{ "query": { "match" : { "body" : { "query" : "cat cats", "operator" : "and" } } } }'
json_cmd "query_stopword_the.json" curl -s -XGET "localhost:9200/_search?pretty" -H "Content-Type: application/json" -d '{ "query": { "match" : { "body" : { "query" : "the"} } } }'

# Section 3 analyzers
cmd "Delete all indices before analyzer section" curl -s -XDELETE "localhost:9200/comments,customer?ignore_unavailable=true"
cmd "Create comments index with my_analyzer" curl -s -XPUT "localhost:9200/comments?pretty" -H "Content-Type: application/json" -d '{"settings":{"analysis":{"analyzer":{"my_analyzer":{"tokenizer":"standard","filter":["lowercase","my_stemmer"]}},"filter":{"my_stemmer":{"type":"stemmer","name":"english"}}}}}'
cmd "Set mapping for body to use my_analyzer" curl -s -XPUT "localhost:9200/comments/_mapping?pretty" -H "Content-Type: application/json" -d '{"properties":{"body":{"type":"text","analyzer":"my_analyzer"}}}'
json_cmd "analyze_my_analyzer.json" curl -s -XPOST "localhost:9200/comments/_analyze?pretty" -H "Content-Type: application/json" -d '{"analyzer":"my_analyzer","text":"I'\''m a :) person, and you?"}'

# Re-index and rerun queries
curl -s -H "Content-Type: application/json" -XPOST "localhost:9200/_bulk" --data-binary @test.json > /dev/null
cmd "Index list (after reindex with custom analyzer)" curl -s "localhost:9200/_cat/indices?v"
json_cmd "query1_cat_after_analyzer.json" curl -s -XGET "localhost:9200/_search?pretty" -H "Content-Type: application/json" -d '{ "query": { "match" : { "body" : { "query" : "cat"} } } }'
json_cmd "query2_cats_after_analyzer.json" curl -s -XGET "localhost:9200/_search?pretty" -H "Content-Type: application/json" -d '{ "query": { "match" : { "body" : { "query" : "cats"} } } }'
json_cmd "query3_cat_cats_and_after_analyzer.json" curl -s -XGET "localhost:9200/_search?pretty" -H "Content-Type: application/json" -d '{ "query": { "match" : { "body" : { "query" : "cat cats", "operator" : "and" } } } }'

# Build a quick summary file with key numbers
{
  echo "query1_max_score=$(jq -r '.hits.max_score' ${OUT_DIR}/query1_cat.json)"
  echo "query2_max_score=$(jq -r '.hits.max_score' ${OUT_DIR}/query2_cats.json)"
  echo "query3_max_score=$(jq -r '.hits.max_score' ${OUT_DIR}/query3_cat_cats_and.json)"
  echo "query1_after_max_score=$(jq -r '.hits.max_score' ${OUT_DIR}/query1_cat_after_analyzer.json)"
  echo "query2_after_max_score=$(jq -r '.hits.max_score' ${OUT_DIR}/query2_cats_after_analyzer.json)"
  echo "query3_after_max_score=$(jq -r '.hits.max_score' ${OUT_DIR}/query3_cat_cats_and_after_analyzer.json)"
  echo "stopword_the_total_hits=$(jq -r '.hits.total.value' ${OUT_DIR}/query_stopword_the.json)"
} > "${OUT_DIR}/summary.txt"

echo "Done. Outputs saved in: ${OUT_DIR}"
echo "Key summary: ${OUT_DIR}/summary.txt"
echo "Commands log: ${OUT_DIR}/elasticcommands.txt"
