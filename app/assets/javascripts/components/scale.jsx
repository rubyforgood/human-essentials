class Scale extends React.Component {
  constructor(props) {
    super(props);

    this.USB_FILTERS = [
      { vendorId: 0x0922, productId: 0x8003 }, // 10lb scale
      { vendorId: 0x0922, productId: 0x8004 } // 25lb scale
    ];

    this.UNIT_MODES = { 2: "g", 11: "oz" };
    this.SCALE_STATES = { 2: "±", 4: "+", 5: "-" };

    this.state = {
      connected: false,
      device: null,
      shouldRead: null,
      weight: "?",
      unit: "",
      scaleState: "",
      errorMsg: null,
      diaperCount: 0,
      diaperKind: null
    };

    if (navigator.usb) {
      navigator.usb.getDevices({ filters: this.USB_FILTERS }).then(devices => {
        devices.forEach(device => {
          this.bindDevice(device);
        });
      });

      navigator.usb.addEventListener("connect", e => {
        console.log("device connected", e);
        this.bindDevice(e.device);
      });

      navigator.usb.addEventListener("disconnect", e => {
        console.log("device lost", e);
        this.disconnect();
      });

      this.connect = () => {
        navigator.usb
          .requestDevice({ filters: this.USB_FILTERS })
          .then(device => this.bindDevice(device))
          .catch(error => {
            console.error(error);
            this.disconnect();
          });
      };
    }

    this.getWeight = this.getWeight.bind(this);
    this.stopWeight = this.stopWeight.bind(this);
    this.bindDevice = this.bindDevice.bind(this);
    this.disconnect = this.disconnect.bind(this);
  }

  getWeight() {
    this.setState({ shouldRead: true });
    const { device } = this.state;
    const { endpointNumber, packetSize } = device.configuration.interfaces[
      0
    ].alternate.endpoints[0];
    let readLoop = () => {
      device
        .transferIn(endpointNumber, packetSize)
        .then(result => {
          let data = new Uint8Array(result.data.buffer);

          let weight = data[4] + 256 * data[5];

          const unit = this.UNIT_MODES[data[2]];

          if (unit === "oz") {
            // Use Math.pow to avoid floating point math.
            weight /= Math.pow(10, 1);
          }

          const scaleState = this.SCALE_STATES[data[1]];

          this.setState({
            weight: weight,
            unit: unit,
            scaleState: scaleState
          });

          if (this.state.shouldRead) {
            readLoop();
          }
        })
        .catch(err => {
          console.error("USB Read Error", err);
        });
    };
    readLoop();
  }

  stopWeight() {
    this.setState({ shouldRead: false });
  }

  getDiaper(event) {
    const count =  Math.trunc(this.state.weight / event.target.value)
    const kind = event.target.name
    this.setState({diaperCount: count})
    this.setState({diaperKind: kind})
  }

  postDiaperCount() {
    const {diaperCount} = this.state;
    const {diaperKind} = this.state;

    fetch('/pdx_bank/donations/scale_intake', {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },      
      body: JSON.stringify({
        number_of_diapers: diaperCount,
        diaper_type: diaperKind,
      })
    })
  }

  bindDevice(device) {
    device
      .open()
      .then(() => {
        console.log(
          `Connected ${device.productName} ${device.manufacturerName}`,
          device
        );
        this.setState({ connected: true, device: device });

        if (device.configuration === null) {
          return device.selectConfiguration(1);
        }
      })
      .then(() => device.claimInterface(0))
      .then(() => this.getWeight())
      .catch(err => {
        console.error("USB Error", err);
        this.setState({ errorMsg: err.message });
      });
  }

  disconnect() {
    this.setState({
      connected: false,
      device: null,
      shouldRead: null,
      weight: "?",
      unit: "",
      scaleState: "",
      errorMsg: ""
    });
  }

  render() {
    const {
      device,
      connected,
      shouldRead,
      weight,
      unit,
      something,
      scaleState,
      errorMsg,
      diaperCount,
      diaperKind
    } = this.state;

    return (
      <main>
        <h1>
          Scale {connected ? "Online" : "Offline"}
        </h1>

        {!navigator.usb &&
          <p>
            Please enable chrome://flags/#enable-experimental-web-platform-features
          </p>}

        {errorMsg &&
          <p>
            {errorMsg}
          </p>}

        {connected &&
          !shouldRead &&
          <button onClick={this.getWeight}>▶</button>}

        {shouldRead && <button onClick={this.stopWeight}>⏸</button>}

        {!device && <button onClick={this.connect}>Register Device</button>}

        {connected &&
          <span className="scale">
            <small>{scaleState}</small>
            <p id="scale_reading">{weight}</p>
            <small>{unit}</small>
          </span>}
          <br/>
          <br/>
      Diaper Type
                <br/>

      <div onChange={event => this.getDiaper(event)}>
        <input type="radio" value="10" name="1"/> Size 1 &nbsp;
        <input type="radio" value="12" name="2"/> Size 2 &nbsp;
        <input type="radio" value="14" name="3"/> Size 3 &nbsp;
        <input type="radio" value="16" name="4"/> Size 4 &nbsp;
        <br/>
        <input type="radio" value="18" name="5"/> Size 5 &nbsp;
        <input type="radio" value="20" name="6"/> Size 6 &nbsp;
        <input type="radio" value="22" name="7"/> Size 7 &nbsp;
        <input type="radio" value="24" name="8"/> Size 8 &nbsp;
      </div>


      <div>
        {diaperCount} Diapers!
      </div>

      <button onClick={() => this.postDiaperCount()} className='button large primary'>Add To Inventory</button>
      </main>
    );
  }
}

class DiaperApp extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      type: 10,
      sc
    }
  }
}
