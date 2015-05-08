using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

using Windows.Devices.Bluetooth.GenericAttributeProfile;
using Windows.Devices.Enumeration;
using Windows.Devices.Enumeration.Pnp;


namespace NeuroBLE
{
	public partial class MainForm : Form
	{

		NeuroBLEProfile Device;
		public MainForm()
		{
			InitializeComponent();

			signalChart.ScaleX = 18;
			signalChart.ScaleY = 6;


			Device = new NeuroBLEProfile();
		}



		private async void RunToolStripButton_Click(object sender, EventArgs e)
		{
			if (RunToolStripButton.Checked == false)
			{
				await Device.Connect();
				drawTimer.Start();

				RunToolStripButton.Checked = true;
			}
			else
			{
				await Device.DisConnect();
				drawTimer.Stop();
				RunToolStripButton.Checked = false;
			}

//			MessageBox.Show("Complete");
		}


		// Нарисовать сигнал
		private void DrawSignal()
		{
			// вычисляем, сколько каналов надо отображать
			int chCount = 0;
			if (ChButton1.Checked == true)
				chCount++;
			if (ChButton2.Checked == true)
				chCount++;
			if (ChButton3.Checked == true)
				chCount++;
			if (ChButton4.Checked == true)
				chCount++;

			if (chCount == 0)
				return;

			double[][] signal = new double[chCount][];
			chCount = 0;
			if (ChButton1.Checked == true)
			{
				signal[chCount] = Device.Signal[0];
				chCount++;
			}
			if (ChButton2.Checked == true)
			{
				signal[chCount] = Device.Signal[1];
				chCount++;
			}
			if (ChButton3.Checked == true)
			{
				signal[chCount] = Device.Signal[2];
				chCount++;
			}
			if (ChButton4.Checked == true)
			{
				signal[chCount] = Device.Signal[3];
				chCount++;
			}


			signalChart.DrawSignal(signal, Device.Length, Device.Length, 250, null);	
		}

		private void drawTimer_Tick(object sender, EventArgs e)
		{
			DrawSignal();
		}

		private void ChButton_Click(object sender, EventArgs e)
		{
			DrawSignal();
		}

/*

		private async Task Connect()
		{
			DeviceInformation bleDevice;

			// берем список подключенных устройств
			var devices = await DeviceInformation.FindAllAsync(
				//								GattDeviceService.GetDeviceSelectorFromUuid(GattServiceUuids.HeartRate),
								GattDeviceService.GetDeviceSelectorFromUuid(NeuroBleGuid),
//GattDeviceService.GetDeviceSelectorFromUuid(GattServiceUuids.GenericAccess),
				new string[] { "System.Devices.ContainerId" });

//			var devices = await DeviceInformation.FindAllAsync(GattDeviceService.GetDeviceSelectorFromUuid(NeuroBleGuid));

			//			var devices = await DeviceInformation.FindAllAsync();
			if (devices.Count == 0)
				return;

			bleDevice = devices[0] as DeviceInformation;


			// инициализируем сервис
//			HeartRateService.Instance.DeviceConnectionUpdated += OnDeviceConnectionUpdated;
			await HeartRateService.Instance.InitializeServiceAsync(bleDevice);

			try
			{
				// Check if the device is initially connected, and display the appropriate message to the user
				var deviceObject = await PnpObject.CreateFromIdAsync(PnpObjectType.DeviceContainer,
					bleDevice.Properties["System.Devices.ContainerId"].ToString(),
					new string[] { "System.Devices.Connected" });

				bool isConnected;
				if (Boolean.TryParse(deviceObject.Properties["System.Devices.Connected"].ToString(), out isConnected))
				{
					MessageBox.Show("Connected");
				}
			}
			catch (Exception e)
			{
				MessageBox.Show("Error");
			}
		}
*/

		// НАчать взаимодействие с устройством
	/*	private void RunToolStripButton_Click(object sender, EventArgs e)
		{

		}*/

	}
}
