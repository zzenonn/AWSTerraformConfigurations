output "bucket_name" {
  value = aws_s3_bucket.app.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.app.arn
}

output "oai" {
  value = aws_cloudfront_origin_access_identity.origin_access_identity.id
}

