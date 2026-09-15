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

namespace CyberPopCampus.ArtManager
{
    internal sealed class ServiceState
    {
        public string Kind = "stopped";
        public string Message = "服务未启动";
        public int ProcessId;
    }

    internal sealed class ControlForm : Form
    {
        private const string ServiceUrl = "http://127.0.0.1:8765/";
        private const string HealthUrl = ServiceUrl + "api/health";
        private const string ExpectedApp = "cyber-pop-art-manager-v4";

        private readonly string projectRoot;
        private readonly Label statusValue;
        private readonly Button startButton;
        private readonly Button openButton;
        private readonly Button stopButton;
        private readonly System.Windows.Forms.Timer timer;
        private bool busy;

        internal string StatusText { get { return statusValue.Text; } }
        internal bool OpenEnabled { get { return openButton.Enabled; } }
        internal void PerformStart() { startButton.PerformClick(); }
        internal void PerformStop() { stopButton.PerformClick(); }

        public ControlForm(string root)
        {
            projectRoot = Path.GetFullPath(root).TrimEnd(Path.DirectorySeparatorChar);
            Text = "美术资源台控制器";
            ClientSize = new Size(640, 286);
            StartPosition = FormStartPosition.CenterScreen;
            FormBorderStyle = FormBorderStyle.FixedSingle;
            MaximizeBox = false;
            BackColor = Html("#0D1D27");
            ForeColor = Html("#EDF9FF");
            Font = new Font("Microsoft YaHei UI", 10F);

            Controls.Add(MakeLabel("美术资源台", 28, 22, 18F, true, "#79E5EF"));
            Controls.Add(MakeLabel("服务状态", 31, 69, 10F, false, "#91AEBC"));
            statusValue = MakeLabel("正在检查…", 116, 66, 10F, true, "#91AEBC");
            statusValue.Size = new Size(490, 25);
            Controls.Add(statusValue);

            Controls.Add(MakeLabel("工作目录", 31, 107, 10F, false, "#91AEBC"));
            TextBox directoryValue = new TextBox();
            directoryValue.Text = projectRoot;
            directoryValue.Location = new Point(116, 102);
            directoryValue.Size = new Size(490, 28);
            directoryValue.ReadOnly = true;
            directoryValue.TabStop = false;
            directoryValue.BorderStyle = BorderStyle.FixedSingle;
            directoryValue.BackColor = Html("#07131A");
            directoryValue.ForeColor = Html("#EDF9FF");
            Controls.Add(directoryValue);

            startButton = MakeButton("启动服务", 31, "#79E5EF", "#062027");
            openButton = MakeButton("打开页面", 232, "#17313D", "#EDF9FF");
            stopButton = MakeButton("停止服务", 433, "#5A2736", "#FFDCE5");
            startButton.TabIndex = 0;
            openButton.TabIndex = 1;
            stopButton.TabIndex = 2;
            Controls.Add(startButton);
            Controls.Add(openButton);
            Controls.Add(stopButton);

            Label address = MakeLabel(ServiceUrl, 31, 241, 10F, false, "#91AEBC");
            address.Size = new Size(575, 22);
            address.TextAlign = ContentAlignment.MiddleCenter;
            Controls.Add(address);

            startButton.Click += async delegate { await StartServerAsync(); };
            openButton.Click += delegate { OpenPage(); };
            stopButton.Click += async delegate { await StopServerAsync(); };

            timer = new System.Windows.Forms.Timer();
            timer.Interval = 1500;
            timer.Tick += delegate { RefreshState(); };
            Shown += delegate { RefreshState(); timer.Start(); Activate(); };
            FormClosed += delegate { timer.Stop(); timer.Dispose(); };
        }

        private static Color Html(string value)
        {
            return ColorTranslator.FromHtml(value);
        }

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

        private static Button MakeButton(string text, int x, string background, string foreground)
        {
            Button button = new Button();
            button.Text = text;
            button.Location = new Point(x, 166);
            button.Size = new Size(176, 52);
            button.FlatStyle = FlatStyle.Flat;
            button.FlatAppearance.BorderSize = 1;
            button.FlatAppearance.BorderColor = Html(background);
            button.BackColor = Html(background);
            button.ForeColor = Html(foreground);
            button.Font = new Font("Microsoft YaHei UI", 10F, FontStyle.Bold);
            button.Cursor = Cursors.Hand;
            return button;
        }

        private bool PortIsOpen()
        {
            using (TcpClient client = new TcpClient())
            {
                try
                {
                    IAsyncResult pending = client.BeginConnect("127.0.0.1", 8765, null, null);
                    return pending.AsyncWaitHandle.WaitOne(180) && client.Connected;
                }
                catch
                {
                    return false;
                }
            }
        }

        private ServiceState GetServiceState()
        {
            try
            {
                HttpWebRequest request = (HttpWebRequest)WebRequest.Create(HealthUrl);
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
                    if (!String.Equals(app, ExpectedApp, StringComparison.Ordinal))
                        return new ServiceState { Kind = "occupied", Message = "端口由其他程序占用" };
                    string serviceRoot = Path.GetFullPath(root).TrimEnd(Path.DirectorySeparatorChar);
                    if (!String.Equals(projectRoot, serviceRoot, StringComparison.OrdinalIgnoreCase))
                        return new ServiceState { Kind = "occupied", Message = "端口由其他工作目录占用" };
                    return new ServiceState { Kind = "running", Message = "服务运行中", ProcessId = processId };
                }
            }
            catch
            {
                if (PortIsOpen())
                    return new ServiceState { Kind = "occupied", Message = "端口已占用，无法确认服务" };
                return new ServiceState();
            }
        }

        private void RefreshState()
        {
            if (busy) return;
            ApplyState(GetServiceState());
        }

        private void ApplyState(ServiceState current)
        {
            if (current.Kind == "running")
            {
                statusValue.Text = String.Format("运行中 · PID {0}", current.ProcessId);
                statusValue.ForeColor = Html("#C9F66D");
                startButton.Enabled = false;
                openButton.Enabled = true;
                stopButton.Enabled = true;
                AcceptButton = openButton;
            }
            else if (current.Kind == "occupied")
            {
                statusValue.Text = current.Message;
                statusValue.ForeColor = Html("#FFD479");
                startButton.Enabled = false;
                openButton.Enabled = false;
                stopButton.Enabled = false;
                AcceptButton = null;
            }
            else
            {
                statusValue.Text = "未启动";
                statusValue.ForeColor = Html("#91AEBC");
                startButton.Enabled = true;
                openButton.Enabled = false;
                stopButton.Enabled = false;
                AcceptButton = startButton;
            }
        }

        private void SetBusy(string text, string color)
        {
            busy = true;
            statusValue.Text = text;
            statusValue.ForeColor = Html(color);
            startButton.Enabled = false;
            openButton.Enabled = false;
            stopButton.Enabled = false;
        }

        private async Task StartServerAsync()
        {
            SetBusy("正在启动…", "#79E5EF");
            try
            {
                await Task.Run(delegate
                {
                    string launcher = Path.Combine(projectRoot, "tools", "art", "asset_manager", "run-server.ps1");
                    ProcessStartInfo info = new ProcessStartInfo("pwsh.exe");
                    info.Arguments = String.Format("-NoProfile -File \"{0}\" -NoOpen", launcher);
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
                        if (process.ExitCode != 0) throw new InvalidOperationException(String.IsNullOrWhiteSpace(error) ? "服务器启动失败" : error.Trim());
                    }
                });
            }
            catch (Exception error)
            {
                MessageBox.Show(this, error.Message, "启动失败", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                busy = false;
                ApplyState(GetServiceState());
            }
        }

        private void OpenPage()
        {
            if (GetServiceState().Kind != "running")
            {
                RefreshState();
                return;
            }
            ProcessStartInfo info = new ProcessStartInfo(ServiceUrl);
            info.UseShellExecute = true;
            Process.Start(info);
        }

        private async Task StopServerAsync()
        {
            ServiceState current = GetServiceState();
            if (current.Kind != "running" || current.ProcessId <= 0)
            {
                ApplyState(current);
                return;
            }
            SetBusy("正在停止…", "#FF8FAC");
            try
            {
                await Task.Run(delegate
                {
                    using (Process process = Process.GetProcessById(current.ProcessId))
                    {
                        process.Kill();
                        process.WaitForExit(2500);
                    }
                });
            }
            catch (Exception error)
            {
                MessageBox.Show(this, error.Message, "停止失败", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                busy = false;
                ApplyState(GetServiceState());
            }
        }
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
                if (File.Exists(Path.Combine(current.FullName, "project.godot")) && File.Exists(Path.Combine(current.FullName, "tools", "art", "asset_manager", "run-server.ps1")))
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
                    form.Show();
                    Application.DoEvents();
                    string initial = form.StatusText;
                    form.PerformStart();
                    bool started = PumpUntil(delegate { return form.StatusText.StartsWith("运行中", StringComparison.Ordinal) && form.OpenEnabled; }, 10000);
                    bool openEnabled = form.OpenEnabled;
                    form.PerformStop();
                    bool stopped = PumpUntil(delegate { return form.StatusText == "未启动"; }, 5000);
                    File.WriteAllLines(Path.GetFullPath(args[1]), new[] {
                        "initial=" + initial,
                        "started=" + started,
                        "open_enabled=" + openEnabled,
                        "stopped=" + stopped
                    });
                    form.Close();
                    Environment.ExitCode = started && openEnabled && stopped ? 0 : 1;
                    return;
                }
                Application.Run(form);
            }
        }
    }
}
