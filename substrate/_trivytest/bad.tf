# TEMPORARY verification fixture — proves the Trivy gate fails on a real
# HIGH/CRITICAL misconfiguration. Removed before M0 merges. Do not build on this.
resource "aws_security_group" "trivy_proof_bad" {
  name        = "trivy-proof-bad"
  description = "Deliberately insecure: open ingress from the public internet"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
