using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Windows.Storage.Streams;

using Windows.Devices.Bluetooth.GenericAttributeProfile;
using Windows.Devices.Enumeration;
using Windows.Devices.Enumeration.Pnp;

namespace NeuroBLE
{
	// 
	// Профиль устройства - ЭЭГ с интерфейсом BLE
	// Содержит 4 сервиса - Generic, Signal, Battery, Device Information
	public class NeuroBLEProfile
	{
		/// <summary>
		/// Подключенное устройстов
		/// </summary>
		public DeviceInformation Device { get; private set; }

		/// <summary>
		/// Сервис заряда аккумулятора
		/// </summary>
		public GattDeviceService BatteryService { get; private set; }

		/// <summary>
		/// Ключевой сервис - Signal
		/// </summary>
		public GattDeviceService SignalService { get; private set; }
		public GattCharacteristic SignalCharacteristic { get; private set; }

		// Данные
		const int CHANNELS_COUNT = 4; 
		public double[][] Signal;
		const int SIGNAL_LEN_MAX = 1000000;

		public int Length;


		private object lockObj = new object();
		/// <summary>
		/// Guid ключевого сервиса - Signal
		/// </summary>
		public static Guid SignalServiceUUID = new Guid("6E400001-B5A3-f393-e0a9-e50e24dcca9e");
		public static Guid SignalServiceSigUUID = new Guid("6E400003-B5A3-f393-e0a9-e50e24dcca9e");


		public NeuroBLEProfile()
		{
			// создаем буферы
			Signal = new double[CHANNELS_COUNT][];
			for (int i = 0; i < Signal.Length; i++)
				Signal[i] = new double[SIGNAL_LEN_MAX];

			Length = 0;

		}

		public async Task Connect()
		{
			Length = 0;
			// Ищем устройство, которое реализует SignalService
			var devices = await Windows.Devices.Enumeration.DeviceInformation.FindAllAsync(
				GattDeviceService.GetDeviceSelectorFromUuid(SignalServiceUUID));
			if (devices.Count == 0)
				return;
			//Connect to the service  
			SignalService = await GattDeviceService.FromIdAsync(devices[0].Id);

			if (SignalService == null)
				return;

			//Get the Signal characteristic  
			SignalCharacteristic = SignalService.GetCharacteristics(SignalServiceSigUUID)[0];
			if (SignalCharacteristic == null)
			{
				SignalService = null;
				return;
			}
			//Subcribe value changed  
			SignalCharacteristic.ValueChanged += sigData_ValueChanged;
			//Set configuration to notify  
			await SignalCharacteristic.WriteClientCharacteristicConfigurationDescriptorAsync(GattClientCharacteristicConfigurationDescriptorValue.Notify);
			//Get the accelerometer configuration characteristic  
			//			var sigConfig = SignalService.GetCharacteristics(new Guid("F000AA12-0451-4000-B000-000000000000"))[0];  
			//Write 1 to start accelerometer sensor  
			//			await sigConfig.WriteValueAsync((new byte[]{1}).AsBuffer()); 
		}


		public async Task DisConnect()
		{

			if (SignalService != null)
			{
				if (SignalCharacteristic != null)
				{
					SignalCharacteristic.ValueChanged -= sigData_ValueChanged;
					await SignalCharacteristic.WriteClientCharacteristicConfigurationDescriptorAsync(GattClientCharacteristicConfigurationDescriptorValue.None);
				}


				SignalCharacteristic = null;
				SignalService = null;
			}
		}


		private void sigData_ValueChanged(GattCharacteristic sender, GattValueChangedEventArgs args)
		{
			byte[] data = new byte[args.CharacteristicValue.Length];

			DataReader.FromBuffer(args.CharacteristicValue).ReadBytes(data);

			// обрабатываем данные
			//			var value = ProcessData(data);
			//			value.Timestamp = args.Timestamp;

			UInt16 indexR = (UInt16)(data[0] | (data[1] << 8));			// номер осчета в пакете
			int indexW = (int)(((UInt32)Length & 0xFFFF0000) | indexR);


			lock (lockObj)
			{
				int pos = 3;
				for (int ch = 0; ch < CHANNELS_COUNT; ch++)
				{
					Signal[ch][indexW] = (Int16)(data[pos] | (data[pos + 1] << 8));
					Signal[ch][indexW + 1] = (Int16)(data[pos + 9] | (data[pos + 10] << 8));
					pos += 2;
				}
				Length = indexW + 2;
			}

		}


	}
}
