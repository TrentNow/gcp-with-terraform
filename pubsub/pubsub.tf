resource "google_pubsub_topic" "pubsub_person" {
  project = "${var.prodproject}"
  name = "person"
}

data "template_file" "publish_data_template" {
  template = "${file("${path.module}/publishers_setup.sh.tpl")}"
  vars {
    project = "${var.prodproject}"
    sleep = 1
    pubsub_topic = "${google_pubsub_topic.pubsub_person.name}"
  }
}

resource "google_compute_instance" "publisher_east_instances" {
  count = 2
  name         = "publisher-load-east-${count.index}"
  project      = "${var.prodproject}"
  machine_type = "f1-micro"
  zone         = "us-east1-b"
  scheduling {
    preemptible  = true
    automatic_restart = false
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-8"
      size  = "60"
      type  = "pd-standard"
    }
  }
  network_interface {
    network = "default"
    access_config {
    }
  }
  service_account {
    scopes = ["https://www.googleapis.com/auth/pubsub"]
  }
  metadata_startup_script = "${data.template_file.publish_data_template.rendered}; "
}

resource "google_compute_instance" "publisher_west_instances" {
  count = 2
  name         = "publisher-load-west-${count.index}"
  project      = "${var.prodproject}"
  machine_type = "f1-micro"
  zone         = "us-west1-a"
  scheduling {
    preemptible  = true
    automatic_restart = false
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-8"
      size  = "60"
      type  = "pd-standard"
    }
  }
  network_interface {
    network = "default"
    access_config {
    }
  }
  service_account {
    scopes = ["https://www.googleapis.com/auth/pubsub"]
  }
  metadata_startup_script = "${data.template_file.publish_data_template.rendered}; "
}







resource "google_pubsub_subscription" "pubsub_person" {
  name  = "person-subscription"
  project = "${var.prodproject}"
  topic = "${google_pubsub_topic.pubsub_person.name}"
  ack_deadline_seconds = 20
}

resource "google_bigquery_dataset" "default" {
  dataset_id                  = "people"
  project                     = "${var.prodproject}"
  friendly_name               = "people"
  description                 = "Person informations"
  location                    = "US"
  labels {
    env = "default"
  }
}

resource "google_bigquery_table" "default" {
  dataset_id = "${google_bigquery_dataset.default.dataset_id}"
  project    = "${var.prodproject}"
  table_id   = "person"
  time_partitioning {
    type = "DAY"
  }
  labels {
    env = "default"
  }
  schema = "${file("${path.module}/schema.json")}"
}



data "template_file" "subscribe_data_template" {
  template = "${file("${path.module}/subscribers_setup.sh.tpl")}"
  vars {
    project = "${var.prodproject}"
    sleep = 1
    bigquery_dataset = "${google_bigquery_dataset.default.dataset_id}"
    bigquery_table = "${google_bigquery_table.default.table_id}"
    subscription = "${google_pubsub_subscription.pubsub_person.name}"
  }
}

resource "google_compute_instance" "subscribertobigquery_west_instances" {
  count = 3
  name         = "subscriber-load-west-${count.index}"
  project      = "${var.prodproject}"
  machine_type = "f1-micro"
  zone         = "us-west1-a"
  scheduling {
    preemptible  = true
    automatic_restart = false
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-8"
      size  = "60"
      type  = "pd-standard"
    }
  }
  network_interface {
    network = "default"
    access_config {
    }
  }
  service_account {
    scopes = ["https://www.googleapis.com/auth/pubsub","https://www.googleapis.com/auth/bigquery","https://www.googleapis.com/auth/bigquery.insertdata"]
  }
  metadata_startup_script = "${data.template_file.subscribe_data_template.rendered}; "
}

