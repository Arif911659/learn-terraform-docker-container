// App.js
import React, { useState, useEffect } from 'react';
import axios from 'axios';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';

function App() {
  const [cases, setCases] = useState([]);
  const [newCase, setNewCase] = useState({
    country: '',
    cases: 0,
    deaths: 0,
    recovered: 0
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchCases();
  }, []);

  const fetchCases = async () => {
    try {
      const response = await axios.get(`${API_URL}/cases/`);
      setCases(response.data);
      setLoading(false);
    } catch (err) {
      setError('Failed to fetch cases');
      setLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await axios.post(`${API_URL}/cases/`, newCase);
      setNewCase({ country: '', cases: 0, deaths: 0, recovered: 0 });
      fetchCases();
    } catch (err) {
      setError('Failed to add new case');
    }
  };

  if (loading) return <div>Loading...</div>;
  if (error) return <div>{error}</div>;

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">COVID-19 Tracking Dashboard</h1>
      
      <div className="mb-8">
        <h2 className="text-xl font-semibold mb-4">Add New Case</h2>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <input
              type="text"
              placeholder="Country"
              value={newCase.country}
              onChange={(e) => setNewCase({...newCase, country: e.target.value})}
              className="border p-2 rounded"
            />
          </div>
          <div>
            <input
              type="number"
              placeholder="Cases"
              value={newCase.cases}
              onChange={(e) => setNewCase({...newCase, cases: parseInt(e.target.value)})}
              className="border p-2 rounded"
            />
          </div>
          <div>
            <input
              type="number"
              placeholder="Deaths"
              value={newCase.deaths}
              onChange={(e) => setNewCase({...newCase, deaths: parseInt(e.target.value)})}
              className="border p-2 rounded"
            />
          </div>
          <div>
            <input
              type="number"
              placeholder="Recovered"
              value={newCase.recovered}
              onChange={(e) => setNewCase({...newCase, recovered: parseInt(e.target.value)})}
              className="border p-2 rounded"
            />
          </div>
          <button type="submit" className="bg-blue-500 text-white px-4 py-2 rounded">
            Add Case
          </button>
        </form>
      </div>

      <div>
        <h2 className="text-xl font-semibold mb-4">Cases List</h2>
        <div className="grid gap-4">
          {cases.map((c, index) => (
            <div key={index} className="border p-4 rounded">
              <h3 className="font-bold">{c.country}</h3>
              <p>Cases: {c.cases}</p>
              <p>Deaths: {c.deaths}</p>
              <p>Recovered: {c.recovered}</p>
              <p>Date: {c.date}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

export default App;