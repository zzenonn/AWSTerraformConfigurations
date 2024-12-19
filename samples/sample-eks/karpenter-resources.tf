resource "aws_sqs_queue" "karpenter_interruption_queue" {
  name                      = "${local.name_tag_prefix}-Cluster-Interruption-Queue"
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true
}

resource "aws_sqs_queue_policy" "karpenter_interruption_queue_policy" {
  queue_url = aws_sqs_queue.karpenter_interruption_queue.id

  policy = templatefile("tpl/sqs_resource_policy.json.tpl", {
    queue_arn = aws_sqs_queue.karpenter_interruption_queue.arn
  })
}

resource "aws_cloudwatch_event_rule" "scheduled_change_rule" {
  name         = "ScheduledChangeRule"
  event_pattern = jsonencode({
    source      = ["aws.health"]
    "detail-type" = ["AWS Health Event"]
  })
}

resource "aws_cloudwatch_event_target" "scheduled_change_rule_target" {
  rule      = aws_cloudwatch_event_rule.scheduled_change_rule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}

resource "aws_cloudwatch_event_rule" "spot_interruption_rule" {
  name         = "SpotInterruptionRule"
  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    "detail-type" = ["EC2 Spot Instance Interruption Warning"]
  })
}

resource "aws_cloudwatch_event_target" "spot_interruption_rule_target" {
  rule      = aws_cloudwatch_event_rule.spot_interruption_rule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}

resource "aws_cloudwatch_event_rule" "rebalance_rule" {
  name         = "RebalanceRule"
  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    "detail-type" = ["EC2 Instance Rebalance Recommendation"]
  })
}

resource "aws_cloudwatch_event_target" "rebalance_rule_target" {
  rule      = aws_cloudwatch_event_rule.rebalance_rule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}

resource "aws_cloudwatch_event_rule" "instance_state_change_rule" {
  name         = "InstanceStateChangeRule"
  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    "detail-type" = ["EC2 Instance State-change Notification"]
  })
}

resource "aws_cloudwatch_event_target" "instance_state_change_rule_target" {
  rule      = aws_cloudwatch_event_rule.instance_state_change_rule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}