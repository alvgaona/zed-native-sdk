use zed::settings::LspSettings;
use zed_extension_api::{self as zed, LanguageServerId, Result};

const BINARY_NAME: &str = "native";

const LOCAL_BINARY: &str = "node_modules/.bin/native";

/// The project's own CLI, if it has one. The extension API has no exists(), so reading is the test.
fn local_binary(worktree: &zed::Worktree) -> Option<String> {
    worktree
        .read_text_file(LOCAL_BINARY)
        .ok()
        .map(|_| format!("{}/{LOCAL_BINARY}", worktree.root_path()))
}

struct NativeSdkExtension;

impl zed::Extension for NativeSdkExtension {
    fn new() -> Self {
        Self
    }

    fn language_server_command(
        &mut self,
        _language_server_id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<zed::Command> {
        // A pinned dependency beats whatever happens to be on PATH.
        let command = local_binary(worktree)
            .or_else(|| worktree.which(BINARY_NAME))
            .ok_or_else(|| {
                "the `native` CLI was not found, so diagnostics, hover and completion are off \
                 (highlighting is unaffected). Install it with `bun add -g @native-sdk/cli`."
                    .to_string()
            })?;

        Ok(zed::Command {
            command,
            args: vec!["markup".to_string(), "lsp".to_string()],
            env: Default::default(),
        })
    }

    fn language_server_workspace_configuration(
        &mut self,
        server_id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<Option<zed::serde_json::Value>> {
        LspSettings::for_worktree(server_id.as_ref(), worktree).map(|settings| settings.settings)
    }
}

zed::register_extension!(NativeSdkExtension);
