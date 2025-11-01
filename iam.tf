resource "aws_iam_user" "deploy_user" {
    name = var.iam_id
}

resource "aws_iam_user_policy_attachment" "deploy_user_attach" {
    user = aws_iam_user.deploy_user.name
    policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"  
}
