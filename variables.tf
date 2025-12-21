variable "github_owner" {
  description = "The GitHub owner (user or organization) for the repository."
  type        = string
  default     = "makeitworkcloud"
}

variable "github_visibility" {
  description = "Public, private, or internal visibility"
  type        = string
  default     = "public"
}
