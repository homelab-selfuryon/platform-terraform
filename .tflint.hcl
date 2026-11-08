# Built-in ruleset only (no plugin download, so CI needs no network beyond `tofu init`).
config {
  call_module_type = "none"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
