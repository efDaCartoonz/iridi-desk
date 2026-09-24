fn main() {
    // Server settings belong to the branded client build, not to a user-editable
    // configuration file. Store them as encoded bytes so a casual string search
    // of the executable does not reveal the deployment endpoints.
    fn get_config_var(env_name: &str) -> String {
        if let Ok(value) = std::env::var(env_name) {
            if !value.trim().is_empty() {
                return value;
            }
        }
        for dot_env in [
            std::path::PathBuf::from(".env"),
            std::path::PathBuf::from("../../.env"),
            std::path::PathBuf::from("../.env"),
        ] {
            if let Ok(content) = std::fs::read_to_string(&dot_env) {
                for line in content.lines() {
                    let line = line.trim();
                    if line.starts_with('#') || line.is_empty() {
                        continue;
                    }
                    if let Some((k, v)) = line.split_once('=') {
                        if k.trim() == env_name {
                            return v.trim().to_string();
                        }
                    }
                }
            }
        }
        String::new()
    }

    fn obfuscated_function(env_name: &str, function_name: &str) -> String {
        let value = get_config_var(env_name);
        let bytes: Vec<u8> = value
            .bytes()
            .enumerate()
            .map(|(index, byte)| byte ^ 0xA7u8.wrapping_add(index as u8).rotate_left(1))
            .collect();
        format!(
            "pub fn {function_name}() -> String {{\n    const DATA: &[u8] = &{:?};\n    String::from_utf8(DATA.iter().enumerate().map(|(index, byte)| byte ^ 0xA7u8.wrapping_add(index as u8).rotate_left(1)).collect()).expect(\"invalid iRidiDesk build configuration\")\n}}\n",
            bytes
        )
    }

    let generated = [
        obfuscated_function("IRIDI_RENDEZVOUS_SERVER", "iridi_rendezvous_server"),
        obfuscated_function("IRIDI_RELAY_SERVER", "iridi_relay_server"),
        obfuscated_function("IRIDI_API_SERVER", "iridi_api_server"),
        obfuscated_function("IRIDI_PUB_KEY", "iridi_pub_key"),
    ]
    .join("\n");
    let build_config = std::path::PathBuf::from(std::env::var("OUT_DIR").unwrap())
        .join("iridi_build_config.rs");
    std::fs::write(build_config, generated).expect("write iRidiDesk build configuration");
    for name in [
        "IRIDI_RENDEZVOUS_SERVER",
        "IRIDI_RELAY_SERVER",
        "IRIDI_API_SERVER",
        "IRIDI_PUB_KEY",
    ] {
        println!("cargo:rerun-if-env-changed={name}");
    }
    println!("cargo:rerun-if-changed=../../.env");
    println!("cargo:rerun-if-changed=.env");

    let out_dir = format!("{}/protos", std::env::var("OUT_DIR").unwrap());

    std::fs::create_dir_all(&out_dir).unwrap();

    protobuf_codegen::Codegen::new()
        .pure()
        .out_dir(out_dir)
        .inputs(["protos/rendezvous.proto", "protos/message.proto"])
        .include("protos")
        .customize(protobuf_codegen::Customize::default().tokio_bytes(true))
        .run()
        .expect("Codegen failed.");
}
