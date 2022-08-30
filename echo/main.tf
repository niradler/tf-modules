resource "null_resource" "echo" {
  triggers = {
    text = var.text
    once = var.once ? 1 : timestamp()
  }
  provisioner "local-exec" {
    command = "echo \"${var.text}\""
  }
}
