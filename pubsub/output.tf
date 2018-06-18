output "pubsub_person" {
 value = "${google_pubsub_topic.pubsub_person.name}"
}

output "bigquery_dataset" {
 value = "${google_bigquery_dataset.default.dataset_id}"
}

output "bigquery_table" {
 value = "${google_bigquery_table.default.table_id}"
}

output "person_subscription" {
 value = "${google_pubsub_subscription.pubsub_person.name}"
}