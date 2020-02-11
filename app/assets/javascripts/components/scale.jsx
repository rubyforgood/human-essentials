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
      manualWeight: 0,
      scaleState: "",
      errorMsg: null,
      diaperCount: 0,
      diaperKind: null
    };
    this.handleChange = this.handleChange.bind(this);

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
    var scaleWeight = parseInt(this.state.weight) || 0;
    const totalWeight = scaleWeight + this.state.manualWeight
    const count =  Math.trunc(totalWeight / event.target.value)
    const kind = event.target.attributes.getNamedItem('label').value
    this.setState({diaperCount: count})
    this.setState({diaperKind: kind})
  }

  handleChange(event) {
    this.setState({manualWeight: event.target.value});
  }

  postDiaperCount() {
    const {diaperCount} = this.state;
    const {diaperKind} = this.state;
    this.setState({manualWeight: 0})
    this.setState({diaperCount: 0})

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
    }).then(response => {
      if (response.status == 200) {
        toastr.success('Diapers Added to Inventory!');
      }
    });
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
      manualWeight,
      diaperCount,
      diaperKind
    } = this.state;

    return (
      <div className="box">
        <div className="box-body">
            <h1>Scale {connected ? "Online" : "Offline"}</h1>
            {!navigator.usb && <p>Please enable chrome://flags/#enable-experimental-web-platform-features</p>}
            {errorMsg && <p> {errorMsg}</p>}
            {connected &&
              !shouldRead &&
              <button onClick={this.getWeight}>▶</button>}
            {shouldRead && <button onClick={this.stopWeight}>⏸</button>}
            {!device && <button onClick={this.connect} className="btn btn-success">Register Device</button>}
            {connected &&
              <span className="scale">
                <small>{scaleState}</small>
                <p id="scale_reading">{weight}</p>
                <small>{unit}</small>
              </span>}
            <br/>
            <br/>
            <br/>
            {!connected &&
              <div className="large-6 small-centered">
                Manual Scale Weight Reading (g): <input type="text" className="" value={this.state.manualWeight} onChange={this.handleChange} />
              </div>}
            <br/>
            <div onChange={event => this.getDiaper(event)} style={{textAlign: 'left'}} className="row">
              <div className="col-xs-8"><strong>Diaper Type</strong></div>
              <div className="col-xs-4"><strong>Total</strong></div>
              <div className="col-xs-4">
                <label style={{fontWeight: 'normal'}}><input type="radio" value="31.18" label={this.props.pu_2t_3t} name="diap"/> Kids Pull-Ups (2T-3T)</label><br/>
                <label style={{fontWeight: 'normal'}}><input type="radio" value="34.02" label={this.props.pu_3t_4t} name="diap"/> Kids Pull-Ups (3T-4T)</label><br/>
                <label style={{fontWeight: 'normal'}}><input type="radio" value="34.02" label={this.props.pu_4t_5t} name="diap"/> Kids Pull-Ups (4T-5T)</label><br/>
                <label style={{fontWeight: 'normal'}}><input type="radio" value="11.34" label={this.props.k_preemie} name="diap"/> Kids (Preemie)</label><br/>
                <label style={{fontWeight: 'normal'}}><input type="radio" value="17.84" label={this.props.k_newborm} name="diap"/> Kids (Newborn)</label>
              </div>
              <div className="col-xs-4">
                <label style={{fontWeight: 'normal'}}><input type="radio" value="22.68" label={this.props.k_size1} name="diap"/> Kids Size 1</label><br/>
                <label style={{fontWeight: 'normal'}}><input type="radio" value="22.68" label={this.props.k_size2} name="diap"/> Kids Size 2</label><br/>
                <label style={{fontWeight: 'normal'}}><input type="radio" value="25.51" label={this.props.k_size3} name="diap"/> Kids Size 3</label><br/>
                <label style={{fontWeight: 'normal'}}><input type="radio" value="36.85" label={this.props.k_size4} name="diap"/> Kids Size 4</label><br/>
                <label style={{fontWeight: 'normal'}}><input type="radio" value="36.69" label={this.props.k_size5} name="diap"/> Kids Size 5</label><br/>
                <label style={{fontWeight: 'normal'}}><input type="radio" value="36.69" label={this.props.k_size6} name="diap"/> Kids Size 6</label>
              </div>
              <div className="col-xs-4">
                <h5>{diaperCount} Diapers!</h5>
                <br/>
                <button onClick={() => this.postDiaperCount()} className='btn btn-primary'>Add To Inventory</button>
              </div>
            </div>
          </div>
        </div>
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
