resource "aws_s3_bucket" "b" {
  bucket = "perfect-bucket"

  tags = {
    Name        = "Perfect Orchastration s3 bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "acl-perfect-bucket" {
  bucket = aws_s3_bucket.b.id
  acl    = "private"
}
