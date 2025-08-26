vpc_config = [{
  subnets = [
    "<enter Private Subnet 1 ID>",
    "<enter Private Subnet 2 ID>"
  ]
  vpc_id = "<enter VPC ID>"
}]

tags = {
  automation  = "terraform"
  repo-name   = "<Current ASC Integration Flows repo name>"   #To be filled
}