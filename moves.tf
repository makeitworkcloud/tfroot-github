# Graduate tfroot-twilio from the temporary relaxed profile without deleting
# and recreating its protected main branch.
moved {
  from = github_branch_protection.relaxed_protections["tfroot-twilio"]
  to   = github_branch_protection.protections["tfroot-twilio"]
}
