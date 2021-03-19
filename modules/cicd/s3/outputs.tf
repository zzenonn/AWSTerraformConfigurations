output "bucket" {
  value = aws_s3_bucket.app
}

output "oai" {
  value = aws_cloudfront_origin_access_identity.origin_access_identity.id
}

