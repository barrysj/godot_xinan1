using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using System.Web.Script.Serialization;
using System.Windows.Forms;

namespace CyberPopCampus.GameLauncher
{
    internal sealed class LaunchForm : Form
    {
#if DEBUG
        internal static readonly string Mode = "Debug";
#else
        internal static readonly string Mode = "Release";
#endif
        internal readonly string Root;
        internal readonly Dictionary<string, Button> Actions = new Dictionary<string, Button>();
        internal Task ActiveTask;
        internal int LastExitCode = -1;
        internal bool VerifyLaunch;
        internal bool CaptureLaunch;
        internal bool TestMode;
        private readonly JavaScriptSerializer json = new JavaScriptSerializer();
        private readonly TextBox engine = new TextBox();
        private readonly ComboBox resolution = new ComboBox();
        private readonly CheckBox fullscreen = new CheckBox();
        private readonly TextBox detail = new TextBox();
        private readonly Label status = new Label();
        private readonly ProgressBar progress = new ProgressBar();
        private readonly List<Control> settingsControls = new List<Control>();
        private readonly Color background, surface, ink, muted, accent, success, danger;
        private bool busy, running;
        private bool sawCompletion, sawError;
        private string lastLog = "";
        private TabControl pages = null;

        internal LaunchForm(string root)
        {
            Root = root.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
            Dictionary<string, object> colors = json.Deserialize<Dictionary<string, object>>(File.ReadAllText(Path.Combine(Root, "data/visual/colors.json")));
            background = Token(colors, "night", "background"); surface = Token(colors, "night", "surface");
            ink = Token(colors, "night", "text_primary"); muted = Token(colors, "daily", "accent_primary");
            accent = Token(colors, "brand", Mode == "Debug" ? "cyan_bright" : "yellow_neon");
            success = Token(colors, "semantic", "success"); danger = Token(colors, "semantic", "danger");
            Text = "Cyber Pop Campus · " + Mode + " 启动器";
            Font = new Font("Microsoft YaHei UI", 10F);
            BackColor = background; ForeColor = ink;
            AutoScaleMode = AutoScaleMode.Dpi;
            ClientSize = Mode == "Debug" ? new Size(900, 750) : new Size(700, 490);
            MinimumSize = Size;
            StartPosition = FormStartPosition.CenterScreen;
            var layout = new TableLayoutPanel { Dock = DockStyle.Fill, Padding = new Padding(24), ColumnCount = 1, RowCount = 5 };
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 94));
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, Mode == "Debug" ? 116 : 90));
            layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, Mode == "Debug" ? 156 : 62));
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 30));
            Controls.Add(layout);
            var heading = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 1, RowCount = 3, Margin = Padding.Empty };
            heading.RowStyles.Add(new RowStyle(SizeType.Absolute, 24));
            heading.RowStyles.Add(new RowStyle(SizeType.Absolute, 46));
            heading.RowStyles.Add(new RowStyle(SizeType.Absolute, 24));
            heading.Controls.Add(Label("CYBER POP CAMPUS  /  " + Mode.ToUpperInvariant(), 10, accent));
            heading.Controls.Add(Label(Mode == "Debug" ? "开发启动器" : "重返校园", 23, ink));
            heading.Controls.Add(Label(Mode == "Debug" ? "选择入口，快速进入当前工作区" : "继续探索，找回校园的记忆", 10, muted));
            layout.Controls.Add(heading, 0, 0);

            var options = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 3, RowCount = 3, Padding = new Padding(0, 6, 0, 10), Margin = Padding.Empty };
            options.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 68));
            options.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            options.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 128));
            options.RowStyles.Add(new RowStyle(SizeType.Absolute, 34));
            options.RowStyles.Add(new RowStyle(SizeType.Absolute, 36));
            options.RowStyles.Add(new RowStyle(SizeType.Absolute, 22));
            var engineLabel = Label("引擎", 10, muted);
            options.Controls.Add(engineLabel, 0, 0);
            engine.Dock = DockStyle.Fill; engine.BackColor = surface; engine.ForeColor = ink; engine.BorderStyle = BorderStyle.FixedSingle; engine.TabIndex = 0;
            options.Controls.Add(engine, 1, 0); settingsControls.Add(engine);
            var browse = Button("选择", false); browse.TabIndex = 1; browse.Margin = new Padding(4, 0, 4, 0); browse.Font = new Font("Microsoft YaHei UI", 10, FontStyle.Bold);
            browse.Click += delegate { using (var picker = new OpenFileDialog { Filter = "Godot 引擎|*.exe", Title = "选择 Godot Windows 引擎" }) { if (picker.ShowDialog(this) == DialogResult.OK) { engine.Text = picker.FileName; try { SaveSettings(); } catch (Exception error) { status.Text = "设置保存失败：" + error.Message; status.ForeColor = danger; } } } };
            options.Controls.Add(browse, 2, 0); settingsControls.Add(browse);
            options.Controls.Add(Label("画面", 10, muted), 0, 1);
            var display = new FlowLayoutPanel { Dock = DockStyle.Fill, WrapContents = false };
            resolution.DropDownStyle = ComboBoxStyle.DropDownList; resolution.Width = 162;
            resolution.Items.AddRange(new object[] { "1920x1080", "2560x1440", "1920x1200" }); resolution.SelectedIndex = 0; resolution.TabIndex = 2;
            display.Controls.Add(resolution); settingsControls.Add(resolution);
            fullscreen.Text = "全屏"; fullscreen.AutoSize = true; fullscreen.Margin = new Padding(16, 4, 0, 0); fullscreen.TabIndex = 3;
            display.Controls.Add(fullscreen); settingsControls.Add(fullscreen);
            options.Controls.Add(display, 1, 1); options.SetColumnSpan(display, 2);
            var location = Label(Mode == "Debug" ? Path.GetFileName(Root) + "  ·  当前工作区" : "正式进度  ·  正式资源", 9, muted);
            location.AutoEllipsis = true; options.Controls.Add(location, 1, 2); options.SetColumnSpan(location, 2);
            new ToolTip().SetToolTip(location, Root);
            if (Mode == "Release") {
                engine.Visible = false; engineLabel.Visible = false;
                options.RowStyles[0].Height = 0;
                browse.Text = "引擎设置"; options.SetCellPosition(browse, new TableLayoutPanelCellPosition(2, 1));
                options.SetColumnSpan(display, 1);
            }
            layout.Controls.Add(options, 0, 1);

#if DEBUG
            var tabs = new TabControl { Dock = DockStyle.Fill, TabIndex = 4 };
            pages = tabs;
            var startPage = new TabPage("启动") { BackColor = surface, ForeColor = ink, Padding = new Padding(12) };
            var checksPage = new TabPage("检查") { BackColor = surface, ForeColor = ink, Padding = new Padding(12) };
            tabs.TabPages.Add(startPage); tabs.TabPages.Add(checksPage);
            var startRows = Rows(3);
            AddAction(startRows, 0, "Battle", "战斗试玩", "原序章战斗 · 四人自动部署 · 独立临时档", true);
            AddAction(startRows, 1, "Campus", "校园调试", "完整探索流程 · F8 调试面板 · 独立调试档", false);
            AddAction(startRows, 2, "Play", "正常游戏", "正式进度与正式资源", false);
            startPage.Controls.Add(startRows);
            var checkRows = Rows(4);
            AddPair(checkRows, 0, "Health", "工程检查", "Repair", "缓存修复", "资源导入、脚本依赖和主流程预检");
            AddPair(checkRows, 1, "SelfCheck", "功能自检", "ContentCheck", "内容检查", "原校园调试回归 / 内容 Resource 校验");
            AddPair(checkRows, 2, "ContentPreview", "内容预览", null, null, "独立预览窗口，查看现有内容配置");
            AddPair(checkRows, 3, "HooksOn", "启用检查", "HooksOff", "关闭检查", "main 更新后自动预检；保留已有 hooks");
            checksPage.Controls.Add(checkRows);
            layout.Controls.Add(tabs, 0, 2);
            AcceptButton = Actions["Battle"];
#else
            var play = Rows(1);
            AddAction(play, 0, "Play", "开始游戏", "使用正式进度 · 自动准备所需资源", true);
            layout.Controls.Add(play, 0, 2);
            AcceptButton = Actions["Play"];
#endif
            var feedback = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 2, RowCount = Mode == "Debug" ? 3 : 2, Padding = new Padding(0, 12, 0, 0) };
            feedback.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            feedback.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 128));
            feedback.RowStyles.Add(new RowStyle(SizeType.Absolute, 42));
            feedback.RowStyles.Add(new RowStyle(SizeType.Absolute, 7));
            if (Mode == "Debug") feedback.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
            status.Text = "就绪"; status.Dock = DockStyle.Fill; status.AutoEllipsis = true; status.ForeColor = success;
            feedback.Controls.Add(status, 0, 0);
            var logs = Button("查看日志", false); logs.TabIndex = 20; logs.Click += delegate { OpenLog(); }; feedback.Controls.Add(logs, 1, 0);
            progress.Dock = DockStyle.Fill; progress.Style = ProgressBarStyle.Marquee; progress.MarqueeAnimationSpeed = 24; progress.Visible = false;
            feedback.Controls.Add(progress, 0, 1); feedback.SetColumnSpan(progress, 2);
            detail.ReadOnly = true; detail.Multiline = true; detail.ScrollBars = ScrollBars.Vertical; detail.Dock = DockStyle.Fill;
            detail.BackColor = surface; detail.ForeColor = ink; detail.BorderStyle = BorderStyle.FixedSingle; detail.TabStop = Mode == "Debug";
            if (Mode == "Debug") { feedback.Controls.Add(detail, 0, 2); feedback.SetColumnSpan(detail, 2); }
            layout.Controls.Add(feedback, 0, 3);
            layout.Controls.Add(Label(Mode == "Debug" ? "Debug 独立存档  ·  美术与地图工具保持独立" : "本地游戏入口  ·  关闭调试能力", 9, muted), 0, 4);
            LoadSettings();
            Shown += delegate { engine.SelectionStart = 0; engine.SelectionLength = 0; (Mode == "Debug" ? Actions["Battle"] : Actions["Play"]).Focus(); };
            FormClosing += delegate(object sender, FormClosingEventArgs e) {
                if (busy && !running) { e.Cancel = true; status.Text = "正在准备或检查，请等待完成后关闭。"; }
            };
        }

        private static Color Token(Dictionary<string, object> colors, string section, string key) { return ColorTranslator.FromHtml((string)((Dictionary<string, object>)colors[section])[key]); }
        private Label Label(string text, float size, Color color) { return new Label { Text = text, Dock = DockStyle.Fill, AutoEllipsis = true, ForeColor = color, Font = new Font("Microsoft YaHei UI", size, size >= 16 ? FontStyle.Bold : FontStyle.Regular), TextAlign = ContentAlignment.MiddleLeft }; }
        private Button Button(string text, bool primary) {
            var button = new Button { Text = text, Dock = DockStyle.Fill, Margin = new Padding(4), FlatStyle = FlatStyle.Flat, BackColor = primary ? accent : surface, ForeColor = primary ? background : ink, Cursor = Cursors.Hand, Font = new Font("Microsoft YaHei UI", 11, FontStyle.Bold) };
            button.FlatAppearance.BorderColor = accent; button.FlatAppearance.BorderSize = 1;
            button.FlatAppearance.MouseOverBackColor = primary ? ControlPaint.Light(accent) : ControlPaint.Light(surface);
            return button;
        }
        private TableLayoutPanel Rows(int count) {
            var table = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 1, RowCount = count };
            for (int i = 0; i < count; i++) table.RowStyles.Add(new RowStyle(SizeType.Percent, 100F / count));
            return table;
        }
        private void AddAction(TableLayoutPanel rows, int row, string action, string title, string explanation, bool primary) {
            var item = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 2, RowCount = 1, Padding = new Padding(6) };
            item.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 170)); item.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            var button = MakeAction(action, title, primary); item.Controls.Add(button, 0, 0);
            button.Dock = DockStyle.None; button.Size = new Size(158, 54); button.Anchor = AnchorStyles.None;
            var description = Label(explanation, 10, muted); description.Margin = new Padding(16, 0, 0, 0); item.Controls.Add(description, 1, 0);
            rows.Controls.Add(item, 0, row);
        }
        private void AddPair(TableLayoutPanel rows, int row, string first, string firstTitle, string second, string secondTitle, string explanation) {
            var item = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 3, RowCount = 1 };
            item.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 128)); item.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 128)); item.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            var firstButton = MakeAction(first, firstTitle, false); item.Controls.Add(firstButton, 0, 0);
            firstButton.Dock = DockStyle.None; firstButton.Size = new Size(118, 44); firstButton.Anchor = AnchorStyles.None;
            if (second != null) { var secondButton = MakeAction(second, secondTitle, false); item.Controls.Add(secondButton, 1, 0); secondButton.Dock = DockStyle.None; secondButton.Size = new Size(118, 44); secondButton.Anchor = AnchorStyles.None; }
            var description = Label(explanation, 9, muted); description.Margin = new Padding(12, 0, 0, 0); item.Controls.Add(description, 2, 0);
            rows.Controls.Add(item, 0, row);
        }
        private Button MakeAction(string action, string title, bool primary) {
            var button = Button(title, primary); button.TabIndex = Actions.Count + 5; Actions.Add(action, button);
            button.Click += delegate { if (!busy) ActiveTask = RunAsync(action); }; return button;
        }
        private string SettingsPath { get { return Path.Combine(Root, ".godot/game-launcher/" + Mode.ToLowerInvariant() + "-settings.json"); } }
        private void LoadSettings() {
            engine.Text = "F:/Applications/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64.exe";
            try {
                string path = SettingsPath;
                if (!File.Exists(path)) path = Path.Combine(Root, ".godot/game-launcher/" + (Mode == "Debug" ? "release" : "debug") + "-settings.json");
                if (File.Exists(path)) {
                    var data = json.Deserialize<Dictionary<string, object>>(File.ReadAllText(path));
                    if (data.ContainsKey("engine")) engine.Text = Convert.ToString(data["engine"]);
                    if (data.ContainsKey("resolution") && resolution.Items.Contains(data["resolution"])) resolution.SelectedItem = data["resolution"];
                    if (data.ContainsKey("fullscreen")) fullscreen.Checked = Convert.ToBoolean(data["fullscreen"]);
                }
            } catch { status.Text = "设置读取失败，请重新选择引擎。"; status.ForeColor = danger; }
        }
        private void SaveSettings() {
            if (TestMode) return;
            Directory.CreateDirectory(Path.GetDirectoryName(SettingsPath));
            File.WriteAllText(SettingsPath, json.Serialize(new { engine = engine.Text.Trim(), resolution = resolution.Text, fullscreen = fullscreen.Checked }), new UTF8Encoding(false));
        }
        private static string Quote(string value) {
            // CommandLineToArgvW quoting; never interpolate shell expressions.
            var result = new StringBuilder("\""); int slashes = 0;
            foreach (char character in value) {
                if (character == '\\') { slashes++; continue; }
                if (character == '"') { result.Append('\\', slashes * 2 + 1); result.Append('"'); }
                else { result.Append('\\', slashes); result.Append(character); }
                slashes = 0;
            }
            result.Append('\\', slashes * 2); result.Append('"'); return result.ToString();
        }
        private async Task RunAsync(string action) {
            busy = true; running = false; sawError = false; sawCompletion = false; LastExitCode = -1; detail.Clear();
            foreach (var button in Actions.Values) button.Enabled = false;
            foreach (var control in settingsControls) control.Enabled = false;
            progress.Visible = true; status.Text = "正在准备…"; status.ForeColor = accent;
            try {
                if (!File.Exists(engine.Text.Trim()) || !engine.Text.Trim().EndsWith(".exe", StringComparison.OrdinalIgnoreCase)) throw new Exception("找不到 Godot 引擎，请点击“选择”设置路径。");
                SaveSettings();
                string backend = Path.Combine(Root, "tools/game_launcher/launch-action.ps1");
                var args = new List<string> { "-NoProfile", "-File", backend, "-Mode", Mode, "-Action", action, "-EnginePath", engine.Text.Trim(), "-Resolution", resolution.Text };
                if (fullscreen.Checked) args.Add("-Fullscreen");
                if (VerifyLaunch) args.Add("-Verify");
                if (CaptureLaunch) args.Add("-Capture");
                string pwsh = FindPowerShell();
                var info = new ProcessStartInfo(pwsh) { WorkingDirectory = Root, UseShellExecute = false, CreateNoWindow = true, RedirectStandardOutput = true, RedirectStandardError = true, StandardOutputEncoding = Encoding.UTF8, StandardErrorEncoding = Encoding.UTF8 };
                info.Arguments = String.Join(" ", args.ConvertAll(Quote));
                using (var process = new Process { StartInfo = info }) {
                    process.OutputDataReceived += delegate(object sender, DataReceivedEventArgs e) { QueueLine(e.Data); };
                    process.ErrorDataReceived += delegate(object sender, DataReceivedEventArgs e) { QueueLine(e.Data); };
                    if (!process.Start()) throw new Exception("无法启动后台检查。");
                    process.BeginOutputReadLine(); process.BeginErrorReadLine();
                    await Task.Run(delegate { process.WaitForExit(); });
                    LastExitCode = process.ExitCode;
                }
                if (LastExitCode != 0 || sawError || !sawCompletion) throw new Exception("操作未完成，请查看日志中的错误。" + (sawError ? "" : " 退出码：" + LastExitCode));
            } catch (Exception error) {
                LastExitCode = 1;
                status.ForeColor = danger;
                if (!sawError) status.Text = error.Message;
                detail.AppendText(error.Message + Environment.NewLine);
            } finally {
                busy = false; running = false; progress.Visible = false;
                foreach (var button in Actions.Values) button.Enabled = true;
                foreach (var control in settingsControls) control.Enabled = true;
            }
        }
        private void QueueLine(string line) {
            if (line == null || IsDisposed || !IsHandleCreated) return;
            try { BeginInvoke((Action)delegate { if (!IsDisposed) ReceiveLine(line); }); } catch (InvalidOperationException) { }
        }
        private void ReceiveLine(string line) {
            detail.AppendText(line + Environment.NewLine);
            if (!line.StartsWith("LAUNCHER_EVENT ", StringComparison.Ordinal)) return;
            try {
                var data = json.Deserialize<Dictionary<string, object>>(line.Substring(15));
                string kind = (string)data["kind"];
                string path = (string)data["path"];
                if (!String.IsNullOrEmpty(path)) lastLog = path;
                if (kind == "log") return;
                running = kind == "running";
                if (kind == "complete") sawCompletion = true;
                if (kind == "error") sawError = true;
                status.Text = (string)data["message"];
                status.ForeColor = kind == "error" ? danger : kind == "complete" ? success : accent;
            } catch { }
        }
        private static string FindPowerShell() {
            string conventional = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "PowerShell/7/pwsh.exe");
            if (File.Exists(conventional)) return conventional;
            foreach (string directory in (Environment.GetEnvironmentVariable("PATH") ?? "").Split(';')) {
                try { string path = Path.Combine(directory.Trim('"'), "pwsh.exe"); if (File.Exists(path)) return path; } catch { }
            }
            throw new Exception("需要 PowerShell 7（pwsh.exe），请安装后再启动。");
        }
        private void OpenLog() {
            try {
                string cache = Path.Combine(Root, ".godot/game-launcher"); Directory.CreateDirectory(cache);
                string transcript = Path.Combine(cache, "last-launcher.log");
                File.WriteAllText(transcript, detail.Text, new UTF8Encoding(false));
                Process.Start(new ProcessStartInfo(File.Exists(lastLog) ? lastLog : transcript) { UseShellExecute = true });
            } catch (Exception error) { status.Text = "无法打开日志：" + error.Message; status.ForeColor = danger; }
        }
        internal void CaptureWindow(string path) {
            Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(path)));
            using (var bitmap = new Bitmap(Width, Height)) { DrawToBitmap(bitmap, new Rectangle(0, 0, Width, Height)); bitmap.Save(path); }
        }
        internal void SetEngine(string value) { engine.Text = value; }
        internal string StatusText { get { return status.Text; } }
        internal void ShowChecks() { if (pages != null) pages.SelectedIndex = 1; }
    }

    internal static class Program
    {
        [STAThread]
        private static int Main(string[] args) {
            Application.EnableVisualStyles(); Application.SetCompatibleTextRenderingDefault(false);
            try {
                string root = AppDomain.CurrentDomain.BaseDirectory;
                while (!File.Exists(Path.Combine(root, "project.godot"))) { var parent = Directory.GetParent(root.TrimEnd(Path.DirectorySeparatorChar)); if (parent == null) throw new Exception("请把启动器放在项目目录中。"); root = parent.FullName; }
                using (var form = new LaunchForm(root)) {
                    string capture = Value(args, "--capture"); string test = Value(args, "--self-test"); string verify = Value(args, "--verify-launch");
                    if (capture == null && test == null && verify == null) { Application.Run(form); return 0; }
                    form.TestMode = true; form.Show(); Application.DoEvents();
                    if (Value(args, "--engine") != null) form.SetEngine(Value(args, "--engine"));
                    if (test != null) RunSelfTest(form, test);
                    if (Array.IndexOf(args, "--checks-page") >= 0) form.ShowChecks();
                    if (verify != null) {
                        if (!form.Actions.ContainsKey(verify)) throw new Exception("此启动器没有该入口：" + verify);
                        form.VerifyLaunch = verify == "Play" || verify == "Campus" || verify == "Battle";
                        form.CaptureLaunch = Array.IndexOf(args, "--game-capture") >= 0;
                        if (!form.VerifyLaunch) { form.ShowChecks(); Application.DoEvents(); }
                        form.Actions[verify].PerformClick();
                        DateTime deadline = DateTime.UtcNow.AddMinutes(8);
                        while (form.ActiveTask != null && !form.ActiveTask.IsCompleted && DateTime.UtcNow < deadline) { Application.DoEvents(); System.Threading.Thread.Sleep(15); }
                        if (form.ActiveTask == null || !form.ActiveTask.IsCompleted) throw new Exception("启动器验证超时。");
                        Application.DoEvents();
                        File.WriteAllText(Path.Combine(root, ".godot/game-launcher/gui-" + LaunchForm.Mode.ToLowerInvariant() + "-" + verify.ToLowerInvariant() + ".json"), new JavaScriptSerializer().Serialize(new { exit_code = form.LastExitCode, message = form.StatusText }));
                        if (form.LastExitCode != 0) { if (capture != null) form.CaptureWindow(capture); form.Close(); return 1; }
                    }
                    if (capture != null) { Application.DoEvents(); form.CaptureWindow(capture); }
                    form.Close(); return 0;
                }
            } catch (Exception error) {
                string result = Value(args, "--self-test");
                if (result != null) { Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(result))); File.WriteAllText(result, "FAILED " + error); }
                if (args.Length == 0) MessageBox.Show(error.Message, "启动器", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return 1;
            }
        }
        private static string Value(string[] args, string key) { int index = Array.IndexOf(args, key); return index >= 0 && index + 1 < args.Length ? args[index + 1] : null; }
        private static void RunSelfTest(LaunchForm form, string path) {
            int checks = 0;
            Action<bool, string> expect = delegate(bool pass, string message) { checks++; if (!pass) throw new Exception(message); };
            expect(form.IsHandleCreated && form.Visible, "实际原生窗口没有显示");
            expect(form.AcceptButton != null, "缺少 Enter 默认入口");
            expect(form.Actions.ContainsKey("Play"), "缺少正常入口");
            expect(form.Actions.ContainsKey("Battle") == (LaunchForm.Mode == "Debug"), "Debug/Release 隔离失败");
            expect(form.Actions.ContainsKey("Repair") == (LaunchForm.Mode == "Debug"), "检查能力隔离失败");
            string[] files = { "GameLauncher.cs", "launcher.manifest", "build-launchers.ps1" };
            var hashes = new List<string>();
            foreach (string file in files) using (var hash = System.Security.Cryptography.SHA256.Create()) hashes.Add(BitConverter.ToString(hash.ComputeHash(File.ReadAllBytes(Path.Combine(form.Root, "tools/game_launcher/" + file)))).Replace("-", ""));
            expect(String.Join(":", hashes) == BuildInfo.Signature, "原生启动器需要重新编译");
            foreach (var button in form.Actions.Values) expect(button.Text.Length >= 2 && button.Text.Length <= 6 && button.TabStop, "动作名或键盘焦点错误");
            Size originalSize = form.ClientSize;
            foreach (var size in new[] { originalSize, new Size(originalSize.Width + 260, originalSize.Height + 140) }) {
                form.ClientSize = size; Application.DoEvents();
                foreach (var button in form.Actions.Values) { expect(button.Width >= 90 && button.Height >= 28, "窗口布局压缩按钮"); }
            }
            form.ClientSize = originalSize; Application.DoEvents();
            Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(path)));
            File.WriteAllText(path, new JavaScriptSerializer().Serialize(new { mode = LaunchForm.Mode, checks = checks, failures = 0 }));
        }
    }
}
