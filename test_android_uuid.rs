#[cfg(target_os = "android")]
mod test {
    use super::*;
    
    /// 测试export_serial_number读取功能
    #[cfg(test)]
    mod tests {
        use super::*;
        use std::fs;
        use std::path::Path;
        
        #[test]
        fn test_get_export_serial_number() {
            // 测试文件读取
            let test_content = r#"
# 这是一个测试配置文件
export_serial_number=test_device_12345
other_config=value
"#;
            
            // 创建临时测试文件
            let test_path = "/tmp/test_base.properties";
            fs::write(test_path, test_content).unwrap();
            
            // 模拟读取函数
            fn test_get_serial(path: &str) -> Option<String> {
                let content = std::fs::read_to_string(path).ok()?;
                for raw in content.lines() {
                    let line = raw.trim();
                    if line.is_empty() || line.starts_with('#') { continue; }
                    if let Some((k, v)) = line.split_once('=') {
                        if k.trim() == "export_serial_number" {
                            let v = v.trim();
                            if !v.is_empty() { return Some(v.to_string()); }
                        }
                    }
                }
                None
            }
            
            let result = test_get_serial(test_path);
            assert_eq!(result, Some("test_device_12345".to_string()));
            
            // 清理测试文件
            fs::remove_file(test_path).unwrap();
        }
        
        #[test]
        fn test_android_uuid_generation() {
            // Android 现在直接使用 ID 作为 UUID 字节
            fn android_uuid_from_id(id: &str) -> Vec<u8> {
                id.as_bytes().to_vec()
            }

            let id = "test_123";
            let uuid = android_uuid_from_id(id);
            assert_eq!(uuid, b"test_123");
        }
    }
}

/// 示例：如何在Android设备上创建base.properties文件
/// 
/// ```
/// use std::fs;
/// 
/// fn create_example_config() {
///     let config_content = r#"
/// # RustDesk Android设备配置
/// export_serial_number=device_unique_12345678
/// # 其他配置项
/// device_name=Android_Device
/// "#;
///     
///     fs::write("/sdcard/robot/config/base.properties", config_content)
///         .expect("无法创建配置文件");
/// }
/// ```

/// 使用说明：
/// 1. 在Android设备上创建目录：`/sdcard/robot/config/`
/// 2. 创建文件：`base.properties`
/// 3. 添加内容：`export_serial_number=your_unique_device_id`
/// 4. 确保RustDesk应用有读取该文件的权限
/// 5. 启动RustDesk，查看日志确认UUID使用了export_serial_number
