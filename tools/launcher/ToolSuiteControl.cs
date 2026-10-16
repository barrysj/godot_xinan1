using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Script.Serialization;
using System.Windows.Forms;

namespace CyberPopCampus.ToolSuite
{
    internal sealed class ServiceState
    {
        public string Kind = "stopped";
        public string Message = "未启动";
        public int ProcessId;
    }

    internal sealed class ToolCard
    {
        public string Key;
        public string Name;
        public string AppId;
        public string Launcher;
        public string Url;
        public int Port;
        public Label Status;
        public TextBox Directory;
        public Button Start;
        public Button Open;
        public Button Stop;
        public bool Busy;
        public string LastError = "";
    }

    internal sealed class ControlForm : Form
    {
        private readonly string projectRoot;
        private readonly ToolCard art;
        private readonly ToolCard map;
        private readonly System.Windows.Forms.Timer timer;
        internal bool SelfTestMode;

        public ControlForm(string root)
        {
            projectRoot = Path.GetFullPath(root).TrimEnd(Path.DirectorySeparatorChar);
            Text = "Cyber Pop Campus · 开发工具集";
            ClientSize = new Size(760, 500);
            StartPosition = FormStartPosition.CenterScreen;
            FormBorderStyle = FormBorderStyle.FixedSingle;
            MaximizeBox = false;
            BackColor = Html("#0D1D27");
            ForeColor = Html("#EDF9FF");
            Font = new Font("Microsoft YaHei UI", 10F);

            Controls.Add(MakeLabel("开发工具集", 24, 17, 19F, true, "#EDF9FF"));
            Controls.Add(MakeLabel("当前工作树的本地服务", 26, 52, 9F, false, "#91AEBC"));
            Controls.Add(MakeLabel("项目目录", 26, 86, 9F, false, "#91AEBC"));
            TextBox rootBox = MakeDirectory(projectRoot, 105, 82, 628);
            Controls.Add(rootBox);

            art = MakeCard("art", "美术资源", 8765, "cyber-pop-art-manager-v4",
                "tools/art/asset_manager/run-server.ps1", 133, "#79E5EF");
            map = MakeCard("map", "地图编辑", 8767, "cyber-pop-campus-map-editor-v1",
                "tools/campus-map-editor/run-server.ps1", 290, "#FFD479");
            Controls.Add(MakeLabel("仅本机可访问 · 关闭工具集不会停止服务", 26, 464, 9F, false, "#91AEBC"));

            timer = new System.Windows.Forms.Timer();
            timer.Interval = 1500;
            timer.Tick += delegate { timer.Stop(); try { RefreshAll(); } finally { timer.Start(); } };
            Shown += delegate { RefreshAll(); timer.Start(); Activate(); };
            FormClosed += delegate { timer.Stop(); timer.Dispose(); };
        }

        private static Color Html(string value) { return ColorTranslator.FromHtml(value); }

        private static Label MakeLabel(string text, int x, int y, float size, bool bold, string color)
        {
            Label label = new Label();
            label.Text = text;
            label.Location = new Point(x, y);
            label.AutoSize = true;
            label.Font = new Font("Microsoft YaHei UI", size, bold ? FontStyle.Bold : FontStyle.Regular);
            label.ForeColor = Html(color);
            return label;
        }

        private static TextBox MakeDirectory(string value, int x, int y, int width)
        {
            TextBox box = new TextBox();
            box.Text = value;
            box.Location = new Point(x, y);
            box.Size = new Size(width, 27);
            box.ReadOnly = true;
            box.TabStop = false;
            box.BorderStyle = BorderStyle.FixedSingle;
            box.BackColor = Html("#07131A");
            box.ForeColor = Html("#EDF9FF");
            return box;
        }

        private static Button MakeButton(string name, int x, int y, string background, string foreground)
        {
            Button button = new Button();
            button.Text = name;
            button.Location = new Point(x, y);
            button.Size = new Size(155, 37);
            button.FlatStyle = FlatStyle.Flat;
            button.FlatAppearance.BorderSize = 1;
            button.FlatAppearance.BorderColor = Html(background);
            button.BackColor = Html(background);
            button.ForeColor = Html(foreground);
            button.Font = new Font("Microsoft YaHei UI", 10F, FontStyle.Bold);
            button.Cursor = Cursors.Hand;
            button.EnabledChanged += delegate
            {
                button.BackColor = Html(button.Enabled ? background : "#1B3540");
                button.ForeColor = Html(button.Enabled ? foreground : "#728997");
                button.FlatAppearance.BorderColor = Html(button.Enabled ? background : "#274654");
            };
            return button;
        }

        private ToolCard MakeCard(string key, string name, int port, string appId, string launcher, int top, string accent)
        {
            Panel panel = new Panel();
            panel.Location = new Point(24, top);
            panel.Size = new Size(712, 145);
            panel.BackColor = Html("#142C39");
            panel.BorderStyle = BorderStyle.FixedSingle;
            Controls.Add(panel);

            ToolCard tool = new ToolCard();
            tool.Key = key;
            tool.Name = name;
            tool.Port = port;
            tool.Url = String.Format("http://127.0.0.1:{0}/", port);
            tool.AppId = appId;
            tool.Launcher = Path.Combine(projectRoot, launcher.Replace('/', Path.DirectorySeparatorChar));
            Label title = MakeLabel(name, 18, 13, 14F, true, accent);
            panel.Controls.Add(title);
            Label address = MakeLabel(tool.Url, 177, 19, 9F, false, "#91AEBC");
            panel.Controls.Add(address);
            tool.Status = MakeLabel("正在检查…", 480, 18, 9F, true, "#91AEBC");
            tool.Status.AutoSize = false;
            tool.Status.Size = new Size(210, 25);
            tool.Status.TextAlign = ContentAlignment.MiddleRight;
            panel.Controls.Add(tool.Status);
            panel.Controls.Add(MakeLabel("运行目录", 20, 56, 9F, false, "#91AEBC"));
            tool.Directory = MakeDirectory(projectRoot, 99, 51, 588);
            panel.Controls.Add(tool.Directory);
            tool.Start = MakeButton("启动", 20, 96, accent, "#062027");
            tool.Open = MakeButton("打开", 188, 96, "#214653", "#EDF9FF");
            tool.Stop = MakeButton("停止", 356, 96, "#5A2736", "#FFDCE5");
            panel.Controls.Add(tool.Start);
            panel.Controls.Add(tool.Open);
            panel.Controls.Add(tool.Stop);
            tool.Start.Click += async delegate { await StartServerAsync(tool); };
            tool.Open.Click += delegate { OpenPage(tool); };
            tool.Stop.Click += async delegate { await StopServerAsync(tool); };
            return tool;
        }

        private static bool PortIsOpen(int port)
        {
            using (TcpClient client = new TcpClient())
            {
                try
                {
                    IAsyncResult pending = client.BeginConnect("127.0.0.1", port, null, null);
                    return pending.AsyncWaitHandle.WaitOne(180) && client.Connected;
                }
                catch { return false; }
            }
        }

        private ServiceState GetServiceState(ToolCard tool)
        {
            try
            {
                HttpWebRequest request = (HttpWebRequest)WebRequest.Create(tool.Url + "api/health");
                request.Timeout = 700;
                request.ReadWriteTimeout = 700;
                request.Proxy = null;
                using (HttpWebResponse response = (HttpWebResponse)request.GetResponse())
                using (StreamReader reader = new StreamReader(response.GetResponseStream()))
                {
                    JavaScriptSerializer serializer = new JavaScriptSerializer();
                    Dictionary<string, object> payload = serializer.Deserialize<Dictionary<string, object>>(reader.ReadToEnd());
                    string app = payload.ContainsKey("app") ? Convert.ToString(payload["app"]) : "";
                    string root = payload.ContainsKey("project_root") ? Convert.ToString(payload["project_root"]) : "";
                    int processId = payload.ContainsKey("process_id") ? Convert.ToInt32(payload["process_id"]) : 0;
                    if (!String.Equals(app, tool.AppId, StringComparison.Ordinal))
                        return new ServiceState { Kind = "occupied", Message = "端口由其他程序占用" };
                    string serviceRoot = Path.GetFullPath(root).TrimEnd(Path.DirectorySeparatorChar);
                    if (!String.Equals(projectRoot, serviceRoot, StringComparison.OrdinalIgnoreCase))
                        return new ServiceState { Kind = "occupied", Message = "端口属于其他工作目录" };
                    if (processId <= 0) return new ServiceState { Kind = "occupied", Message = "服务 PID 无效" };
                    return new ServiceState { Kind = "running", Message = "运行中", ProcessId = processId };
                }
            }
            catch
            {
                if (PortIsOpen(tool.Port))
                    return new ServiceState { Kind = "occupied", Message = "端口已占用，服务无法核验" };
                return new ServiceState();
            }
        }

        private void RefreshAll()
        {
            if (!art.Busy) ApplyState(art, GetServiceState(art));
            if (!map.Busy) ApplyState(map, GetServiceState(map));
        }

        private static void ApplyState(ToolCard tool, ServiceState current)
        {
            if (current.Kind == "running")
            {
                tool.Status.Text = String.Format("运行中 · PID {0}", current.ProcessId);
                tool.Status.ForeColor = Html("#C9F66D");
                tool.Start.Enabled = false;
                tool.Open.Enabled = true;
                tool.Stop.Enabled = true;
            }
            else if (current.Kind == "occupied")
            {
                tool.Status.Text = current.Message;
                tool.Status.ForeColor = Html("#FFD479");
                tool.Start.Enabled = false;
                tool.Open.Enabled = false;
                tool.Stop.Enabled = false;
            }
            else
            {
                tool.Status.Text = "未启动";
                tool.Status.ForeColor = Html("#91AEBC");
                tool.Start.Enabled = true;
                tool.Open.Enabled = false;
                tool.Stop.Enabled = false;
            }
        }

        private static void SetBusy(ToolCard tool, string text, string color)
        {
            tool.Busy = true;
            tool.Status.Text = text;
            tool.Status.ForeColor = Html(color);
            tool.Start.Enabled = false;
            tool.Open.Enabled = false;
            tool.Stop.Enabled = false;
        }

        private async Task StartServerAsync(ToolCard tool)
        {
            if (GetServiceState(tool).Kind != "stopped") { ApplyState(tool, GetServiceState(tool)); return; }
            SetBusy(tool, "正在启动…", "#79E5EF");
            try
            {
                await Task.Run(delegate
                {
                    ProcessStartInfo info = new ProcessStartInfo("pwsh.exe");
                    info.Arguments = String.Format("-NoProfile -File \"{0}\" -NoOpen", tool.Launcher);
                    info.WorkingDirectory = projectRoot;
                    info.UseShellExecute = false;
                    info.CreateNoWindow = true;
                    info.RedirectStandardOutput = true;
                    info.RedirectStandardError = true;
                    using (Process process = Process.Start(info))
                    {
                        string error = process.StandardError.ReadToEnd();
                        process.StandardOutput.ReadToEnd();
                        process.WaitForExit();
                        if (process.ExitCode != 0)
                            throw new InvalidOperationException(String.IsNullOrWhiteSpace(error) ? "服务启动失败" : error.Trim());
                    }
                });
            }
            catch (Exception error)
            {
                tool.LastError = error.Message;
                if (!SelfTestMode) MessageBox.Show(this, error.Message, tool.Name + "启动失败", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                tool.Busy = false;
                ApplyState(tool, GetServiceState(tool));
            }
        }

        private void OpenPage(ToolCard tool)
        {
            if (GetServiceState(tool).Kind != "running") { ApplyState(tool, GetServiceState(tool)); return; }
            ProcessStartInfo info = new ProcessStartInfo(tool.Url);
            info.UseShellExecute = true;
            Process.Start(info);
        }

        private async Task StopServerAsync(ToolCard tool)
        {
            ServiceState selected = GetServiceState(tool);
            if (selected.Kind != "running") { ApplyState(tool, selected); return; }
            SetBusy(tool, "正在停止…", "#FF8FAC");
            try
            {
                await Task.Run(delegate
                {
                    ServiceState verified = GetServiceState(tool);
                    if (verified.Kind != "running" || verified.ProcessId != selected.ProcessId)
                        throw new InvalidOperationException("服务身份已变化，未停止任何进程");
                    using (Process process = Process.GetProcessById(verified.ProcessId))
                    {
                        process.Kill();
                        process.WaitForExit(2500);
                    }
                });
            }
            catch (Exception error)
            {
                tool.LastError = error.Message;
                if (!SelfTestMode) MessageBox.Show(this, error.Message, tool.Name + "停止失败", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                tool.Busy = false;
                ApplyState(tool, GetServiceState(tool));
            }
        }

        internal string StatusText(string key) { return (key == "art" ? art : map).Status.Text; }
        internal bool OpenEnabled(string key) { return (key == "art" ? art : map).Open.Enabled; }
        internal bool StopEnabled(string key) { return (key == "art" ? art : map).Stop.Enabled; }
        internal string LastError(string key) { return (key == "art" ? art : map).LastError; }
        internal void PerformStart(string key) { (key == "art" ? art : map).Start.PerformClick(); }
        internal async void PerformStop(string key) { await StopServerAsync(key == "art" ? art : map); }
    }

    internal static class Program
    {
        private static bool PumpUntil(Func<bool> predicate, int timeoutMilliseconds)
        {
            Stopwatch timer = Stopwatch.StartNew();
            while (timer.ElapsedMilliseconds < timeoutMilliseconds)
            {
                Application.DoEvents();
                if (predicate()) return true;
                Thread.Sleep(50);
            }
            Application.DoEvents();
            return predicate();
        }

        private static string FindProjectRoot()
        {
            DirectoryInfo current = new DirectoryInfo(AppDomain.CurrentDomain.BaseDirectory);
            while (current != null)
            {
                if (File.Exists(Path.Combine(current.FullName, "project.godot")) &&
                    File.Exists(Path.Combine(current.FullName, "tools", "art", "asset_manager", "run-server.ps1")) &&
                    File.Exists(Path.Combine(current.FullName, "tools", "campus-map-editor", "run-server.ps1")))
                    return current.FullName;
                current = current.Parent;
            }
            throw new DirectoryNotFoundException("找不到当前项目目录");
        }

        [STAThread]
        private static void Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            using (ControlForm form = new ControlForm(FindProjectRoot()))
            {
                if (args.Length == 2 && args[0] == "--screenshot")
                {
                    form.Show();
                    Application.DoEvents();
                    using (Bitmap image = new Bitmap(form.Width, form.Height))
                    {
                        form.DrawToBitmap(image, new Rectangle(0, 0, form.Width, form.Height));
                        image.Save(Path.GetFullPath(args[1]));
                    }
                    form.Close();
                    return;
                }
                if (args.Length == 2 && args[0] == "--self-test")
                {
                    form.SelfTestMode = true;
                    form.Show();
                    Application.DoEvents();
                    List<string> report = new List<string>();
                    bool success = true;
                    foreach (string key in new[] { "art", "map" })
                    {
                        string initial = form.StatusText(key);
                        bool preexisting = initial.StartsWith("运行中", StringComparison.Ordinal);
                        if (!preexisting) form.PerformStart(key);
                        bool started = PumpUntil(delegate { return form.StatusText(key).StartsWith("运行中", StringComparison.Ordinal) && form.OpenEnabled(key) && form.StopEnabled(key); }, 30000);
                        bool openEnabled = form.OpenEnabled(key);
                        bool stopEnabled = form.StopEnabled(key);
                        if (!preexisting && form.StatusText(key).StartsWith("运行中", StringComparison.Ordinal)) form.PerformStop(key);
                        bool stopped = PumpUntil(delegate { return preexisting ? form.StatusText(key).StartsWith("运行中", StringComparison.Ordinal) : form.StatusText(key) == "未启动"; }, 7000);
                        report.Add(key + ".initial=" + initial);
                        report.Add(key + ".preexisting=" + preexisting);
                        report.Add(key + ".started=" + started);
                        report.Add(key + ".open_enabled=" + openEnabled);
                        report.Add(key + ".stop_enabled=" + stopEnabled);
                        report.Add(key + ".stopped=" + stopped);
                        report.Add(key + ".error=" + form.LastError(key));
                        success &= started && openEnabled && stopEnabled && stopped;
                    }
                    File.WriteAllLines(Path.GetFullPath(args[1]), report.ToArray());
                    form.Close();
                    Environment.ExitCode = success ? 0 : 1;
                    return;
                }
                Application.Run(form);
            }
        }
    }
}
