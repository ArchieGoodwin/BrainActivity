namespace NeuroBLE
{
	partial class MainForm
	{
		/// <summary>
		/// Требуется переменная конструктора.
		/// </summary>
		private System.ComponentModel.IContainer components = null;

		/// <summary>
		/// Освободить все используемые ресурсы.
		/// </summary>
		/// <param name="disposing">истинно, если управляемый ресурс должен быть удален; иначе ложно.</param>
		protected override void Dispose(bool disposing)
		{
			if (disposing && (components != null))
			{
				components.Dispose();
			}
			base.Dispose(disposing);
		}

		#region Код, автоматически созданный конструктором форм Windows

		/// <summary>
		/// Обязательный метод для поддержки конструктора - не изменяйте
		/// содержимое данного метода при помощи редактора кода.
		/// </summary>
		private void InitializeComponent()
		{
			this.components = new System.ComponentModel.Container();
			System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(MainForm));
			this.signalChart = new SignalView.SignalChart();
			this.toolStrip = new System.Windows.Forms.ToolStrip();
			this.RunToolStripButton = new System.Windows.Forms.ToolStripButton();
			this.toolStripSeparator1 = new System.Windows.Forms.ToolStripSeparator();
			this.ChButton1 = new System.Windows.Forms.ToolStripButton();
			this.ChButton2 = new System.Windows.Forms.ToolStripButton();
			this.ChButton3 = new System.Windows.Forms.ToolStripButton();
			this.ChButton4 = new System.Windows.Forms.ToolStripButton();
			this.drawTimer = new System.Windows.Forms.Timer(this.components);
			this.toolStrip.SuspendLayout();
			this.SuspendLayout();
			// 
			// signalChart
			// 
			this.signalChart.BackColor = System.Drawing.SystemColors.Control;
			this.signalChart.Dock = System.Windows.Forms.DockStyle.Fill;
			this.signalChart.Location = new System.Drawing.Point(0, 25);
			this.signalChart.MinimumSize = new System.Drawing.Size(500, 440);
			this.signalChart.Name = "signalChart";
			this.signalChart.PeakDetector = false;
			this.signalChart.ScaleX = 14;
			this.signalChart.ScaleY = 10;
			this.signalChart.Size = new System.Drawing.Size(835, 740);
			this.signalChart.TabIndex = 0;
			// 
			// toolStrip
			// 
			this.toolStrip.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.RunToolStripButton,
            this.toolStripSeparator1,
            this.ChButton1,
            this.ChButton2,
            this.ChButton3,
            this.ChButton4});
			this.toolStrip.Location = new System.Drawing.Point(0, 0);
			this.toolStrip.Name = "toolStrip";
			this.toolStrip.RenderMode = System.Windows.Forms.ToolStripRenderMode.System;
			this.toolStrip.Size = new System.Drawing.Size(835, 25);
			this.toolStrip.TabIndex = 2;
			this.toolStrip.Text = "toolStrip";
			// 
			// RunToolStripButton
			// 
			this.RunToolStripButton.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Image;
			this.RunToolStripButton.Image = ((System.Drawing.Image)(resources.GetObject("RunToolStripButton.Image")));
			this.RunToolStripButton.ImageTransparentColor = System.Drawing.Color.Magenta;
			this.RunToolStripButton.Name = "RunToolStripButton";
			this.RunToolStripButton.Size = new System.Drawing.Size(23, 22);
			this.RunToolStripButton.Text = "Подключиться к прибору";
			this.RunToolStripButton.Click += new System.EventHandler(this.RunToolStripButton_Click);
			// 
			// toolStripSeparator1
			// 
			this.toolStripSeparator1.Name = "toolStripSeparator1";
			this.toolStripSeparator1.Size = new System.Drawing.Size(6, 25);
			// 
			// ChButton1
			// 
			this.ChButton1.Checked = true;
			this.ChButton1.CheckOnClick = true;
			this.ChButton1.CheckState = System.Windows.Forms.CheckState.Checked;
			this.ChButton1.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Image;
			this.ChButton1.Image = ((System.Drawing.Image)(resources.GetObject("ChButton1.Image")));
			this.ChButton1.ImageTransparentColor = System.Drawing.Color.Magenta;
			this.ChButton1.Name = "ChButton1";
			this.ChButton1.Size = new System.Drawing.Size(23, 22);
			this.ChButton1.Text = "ChButton1";
			this.ChButton1.Click += new System.EventHandler(this.ChButton_Click);
			// 
			// ChButton2
			// 
			this.ChButton2.Checked = true;
			this.ChButton2.CheckOnClick = true;
			this.ChButton2.CheckState = System.Windows.Forms.CheckState.Checked;
			this.ChButton2.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Image;
			this.ChButton2.Image = ((System.Drawing.Image)(resources.GetObject("ChButton2.Image")));
			this.ChButton2.ImageTransparentColor = System.Drawing.Color.Magenta;
			this.ChButton2.Name = "ChButton2";
			this.ChButton2.Size = new System.Drawing.Size(23, 22);
			this.ChButton2.Text = "ChButton2";
			this.ChButton2.Click += new System.EventHandler(this.ChButton_Click);
			// 
			// ChButton3
			// 
			this.ChButton3.Checked = true;
			this.ChButton3.CheckOnClick = true;
			this.ChButton3.CheckState = System.Windows.Forms.CheckState.Checked;
			this.ChButton3.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Image;
			this.ChButton3.Image = ((System.Drawing.Image)(resources.GetObject("ChButton3.Image")));
			this.ChButton3.ImageTransparentColor = System.Drawing.Color.Magenta;
			this.ChButton3.Name = "ChButton3";
			this.ChButton3.Size = new System.Drawing.Size(23, 22);
			this.ChButton3.Text = "ChButton3";
			this.ChButton3.Click += new System.EventHandler(this.ChButton_Click);
			// 
			// ChButton4
			// 
			this.ChButton4.Checked = true;
			this.ChButton4.CheckOnClick = true;
			this.ChButton4.CheckState = System.Windows.Forms.CheckState.Checked;
			this.ChButton4.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Image;
			this.ChButton4.Image = ((System.Drawing.Image)(resources.GetObject("ChButton4.Image")));
			this.ChButton4.ImageTransparentColor = System.Drawing.Color.Magenta;
			this.ChButton4.Name = "ChButton4";
			this.ChButton4.Size = new System.Drawing.Size(23, 22);
			this.ChButton4.Text = "ChButton4";
			this.ChButton4.Click += new System.EventHandler(this.ChButton_Click);
			// 
			// drawTimer
			// 
			this.drawTimer.Tick += new System.EventHandler(this.drawTimer_Tick);
			// 
			// MainForm
			// 
			this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
			this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
			this.ClientSize = new System.Drawing.Size(835, 765);
			this.Controls.Add(this.signalChart);
			this.Controls.Add(this.toolStrip);
			this.Name = "MainForm";
			this.Text = "NeuroBLE";
			this.toolStrip.ResumeLayout(false);
			this.toolStrip.PerformLayout();
			this.ResumeLayout(false);
			this.PerformLayout();

		}

		#endregion

		private SignalView.SignalChart signalChart;
		private System.Windows.Forms.ToolStrip toolStrip;
		private System.Windows.Forms.ToolStripButton RunToolStripButton;
		private System.Windows.Forms.Timer drawTimer;
		private System.Windows.Forms.ToolStripSeparator toolStripSeparator1;
		private System.Windows.Forms.ToolStripButton ChButton1;
		private System.Windows.Forms.ToolStripButton ChButton2;
		private System.Windows.Forms.ToolStripButton ChButton3;
		private System.Windows.Forms.ToolStripButton ChButton4;

	}
}

