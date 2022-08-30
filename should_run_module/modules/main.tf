output "hash_sha256" {
  value = sha256("hello world")
}

output "hash_md5" {
  value = md5("hello world2")
}

resource "random_string" "random" {
  length           = 16
  special          = true
  override_special = "/@£$"
}


output "random" {
  value = random_string.random.result
}
