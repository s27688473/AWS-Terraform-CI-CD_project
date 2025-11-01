

# -----------------------------------------------------------------------------
# 1. NAT INSTANCE A (nat_a)
# - 移除 security_groups 參數
# - 新增 lifecycle 塊來忽略 Provider 帶來的隱含變更
# -----------------------------------------------------------------------------
resource "aws_instance" "nat_a" {
  depends_on      = [aws_db_instance.main_db]
  ami             = "ami-003ed299ad852cb1f"
  instance_type   = var.instance_type
  subnet_id       = aws_subnet.subnet_public_a.id
  associate_public_ip_address = true
  # 【已移除】security_groups = [aws_security_group.security_groups_nat.id]
  source_dest_check = false
  key_name        = "main"
  
  tags = {
    Name = "nat-instance-a"
  }
  
  # 忽略會導致實例重建的屬性（安全組和根設備）
  lifecycle {
    ignore_changes = [
      vpc_security_group_ids,
      security_groups,
      root_block_device,
      metadata_options,
      capacity_reservation_specification,
      cpu_options,
      credit_specification,
      enclave_options,
      maintenance_options,
      primary_network_interface,
      private_dns_name_options,
    ]
  }
}

# -----------------------------------------------------------------------------
# 2. NAT INSTANCE C (nat_c)
# - 新增 lifecycle 塊並確保安全組通過附件資源處理
# -----------------------------------------------------------------------------
resource "aws_instance" "nat_c" {
  depends_on      = [aws_db_instance.main_db]
  ami             = "ami-003ed299ad852cb1f"
  instance_type   = var.instance_type
  subnet_id       = aws_subnet.subnet_public_c.id
  associate_public_ip_address = true
  # 注意：原始配置中此處已無 security_groups，我們將通過 attachment 資源處理
  source_dest_check = false
  key_name        = "main"
  
  tags = {
    Name = "nat-instance-c"
  }
  
  # 忽略會導致實例重建的屬性（安全組和根設備）
  lifecycle {
    ignore_changes = [
      vpc_security_group_ids,
      security_groups,
      root_block_device,
      metadata_options,
      capacity_reservation_specification,
      cpu_options,
      credit_specification,
      enclave_options,
      maintenance_options,
      primary_network_interface,
      private_dns_name_options,
    ]
  }
}

# -----------------------------------------------------------------------------
# 3. WEB INSTANCE A (web_a)
# - 移除 security_groups 參數
# - 新增 lifecycle 塊來忽略 Provider 帶來的隱含變更
# -----------------------------------------------------------------------------
resource "aws_instance" "web_a" {
  depends_on      = [aws_instance.nat_a]
  ami             = var.ami_id
  instance_type   = var.instance_type
  subnet_id       = aws_subnet.subnet_private_a.id
  # 【已移除】security_groups = [aws_security_group.security_groups_web.id]
  key_name        = "main"
  iam_instance_profile = "main"
  user_data = templatefile("${path.module}/userdata.tpl", {
    app_name      = "web-a" 
    db_host       = aws_db_instance.main_db.address
    db_user       = local.rds_credentials.username
    db_password   = local.rds_credentials.password
    db_database   = aws_db_instance.main_db.db_name
  })
  
  tags = {
    Name = "web-a"
  }
  
  # 忽略會導致實例重建的屬性（安全組和根設備）
  lifecycle {
    ignore_changes = [
      vpc_security_group_ids,
      security_groups,
      root_block_device,
      metadata_options,
      capacity_reservation_specification,
      cpu_options,
      credit_specification,
      enclave_options,
      maintenance_options,
      primary_network_interface,
      private_dns_name_options,
    ]
  }
}

# -----------------------------------------------------------------------------
# 4. WEB INSTANCE C (web_c)
# - 移除 security_groups 參數
# - 新增 lifecycle 塊來忽略 Provider 帶來的隱含變更
# -----------------------------------------------------------------------------
resource "aws_instance" "web_c" {
  depends_on      = [aws_instance.nat_a]
  ami             = var.ami_id
  instance_type   = var.instance_type
  subnet_id       = aws_subnet.subnet_private_c.id
  # 【已移除】security_groups = [aws_security_group.security_groups_web.id]
  key_name        = "main"
  iam_instance_profile = "main"
  user_data = templatefile("${path.module}/userdata.tpl", {
    app_name      = "web-c"
    db_host       = aws_db_instance.main_db.address
    db_user       = local.rds_credentials.username
    db_password   = local.rds_credentials.password
    db_database   = aws_db_instance.main_db.db_name
  })
  
  tags = {
    Name = "web-c"
  }
  
  # 忽略會導致實例重建的屬性（安全組和根設備）
  lifecycle {
    ignore_changes = [
      vpc_security_group_ids,
      security_groups,
      root_block_device,
      metadata_options,
      capacity_reservation_specification,
      cpu_options,
      credit_specification,
      enclave_options,
      maintenance_options,
      primary_network_interface,
      private_dns_name_options,
    ]
  }
}

# -----------------------------------------------------------------------------
# 5. 新增：安全組附件資源 (Attachments)
#    這是新的最佳實踐，確保安全組變更不會觸發 EC2 實例重建
# -----------------------------------------------------------------------------

# NAT A 實例的安全組附件
resource "aws_network_interface_sg_attachment" "nat_a_sg_attachment" {
  security_group_id    = aws_security_group.security_groups_nat.id
  network_interface_id = aws_instance.nat_a.primary_network_interface_id
}

# NAT C 實例的安全組附件
resource "aws_network_interface_sg_attachment" "nat_c_sg_attachment" {
  security_group_id    = aws_security_group.security_groups_nat.id
  network_interface_id = aws_instance.nat_c.primary_network_interface_id
}

# Web A 實例的安全組附件
resource "aws_network_interface_sg_attachment" "web_a_sg_attachment" {
  security_group_id    = aws_security_group.security_groups_web.id
  network_interface_id = aws_instance.web_a.primary_network_interface_id
}

# Web C 實例的安全組附件
resource "aws_network_interface_sg_attachment" "web_c_sg_attachment" {
  security_group_id    = aws_security_group.security_groups_web.id
  network_interface_id = aws_instance.web_c.primary_network_interface_id
}
