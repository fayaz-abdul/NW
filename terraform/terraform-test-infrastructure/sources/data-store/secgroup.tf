resource "aws_security_group" "redshift" {
  name        = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "redshift", "secgroup")))}"
  description = "Control security for Redshift instances"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"
}

resource "aws_security_group" "oracle" {
  name        = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "oracle_rds", "secgroup")))}"
  description = "Control security for data store oracle RDS"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"
}

resource "aws_security_group" "sftp_efs" {
  name        = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "sftp_efs", "secgroup")))}"
  description = "Control security for data store EFS SFTP"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"
}

resource "aws_security_group" "sftp_server" {
  name        = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "sftp_server", "secgroup")))}"
  description = "Control security for data store SFTP servers"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"
}

resource "aws_security_group" "sqlserver" {
  name        = "${join("-", compact(list(var.environment, var.customer, var.project, var.role, var.application, "sqlserver_rds", "secgroup")))}"
  description = "Control security for data store sqlserver RDS"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"
}
