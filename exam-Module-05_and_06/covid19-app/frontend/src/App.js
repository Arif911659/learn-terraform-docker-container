import React, { useEffect, useState } from 'react';
import axios from 'axios';

function App() {
  const [covidData, setCovidData] = useState(null);

  useEffect(() => {
    axios.get('/api/covid-data')
      .then(response => setCovidData(response.data))
      .catch(error => console.error('Error fetching data:', error));
  }, []);

  return (
    <div className="App">
      <h1>COVID-19 Statistics</h1>
      {covidData ? (
        <div>
          <h2>Global Statistics</h2>
          <p>New Confirmed: {covidData.Global.NewConfirmed}</p>
          <p>Total Confirmed: {covidData.Global.TotalConfirmed}</p>
          <p>Total Deaths: {covidData.Global.TotalDeaths}</p>
        </div>
      ) : (
        <p>Loading data...</p>
      )}
    </div>
  );
}

export default App;