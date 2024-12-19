{
  "Version": "2008-10-17",
  "Id": "EC2InterruptionPolicy",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "sqs.amazonaws.com",
          "events.amazonaws.com"
        ]
      },
      "Action": "sqs:SendMessage",
      "Resource": "${queue_arn}"
    },
    {
      "Sid": "DenyHTTP",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "sqs:*",
      "Resource": "${queue_arn}",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
