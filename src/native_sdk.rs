use zed::settings::LspSettings;
use zed_extension_api::{self as zed, LanguageServerId, Result};

const BINARY_NAME: &str = "native";

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
        // The server is a subcommand of the SDK's own CLI, so there is nothing to download and
        // nothing to keep in sync — whichever `native` the project builds with is the one that
        // checks the markup.
        let command = worktree.which(BINARY_NAME).ok_or_else(|| {
            "`native` was not found on PATH — install the Native SDK CLI with \
             `bun add -g @native-sdk/cli`"
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
