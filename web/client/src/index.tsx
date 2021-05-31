import React from "react";
import ReactDOM from "react-dom";


interface WeatherProps {
    city?: string;
}

const Weather = React.memo<WeatherProps>((props) => {
    const { city, ...rest } = props;
    const [weather, setWeather] = React.useState({ city: "", datetime: "", weather: "" });
    const [error, setError] = React.useState(false);

    React.useEffect(() => {
        if (city) {
            setError(false);

            const abortController = new AbortController();
            fetchWeather(city, abortController.signal)
                .then(json => {
                    setWeather(json);
                })
                .catch(() => {
                    setError(true);
                });

            return () => {
                abortController.abort();
            };
        }
    }, [city, setWeather, setError]);

    const content = error
        ? "Error!"
        : (<>
            <div>City: {weather.city}</div>
            <div>Date: {weather.datetime}</div>
            <div>Weather: {weather.weather}</div>
        </>);

    return <div {...rest}>
        {content}
    </div>
});

async function fetchWeather(cityName: string, signal: AbortSignal) {
    const response = await fetch(`/api/weather?city=${encodeURIComponent(cityName)}`, { signal });
    const { city, datetime, weather } = await response.json();
    return { city, datetime, weather };
}

interface EditFormProps {
    onSubmit: (city: string) => void;
}

const EditForm = React.memo<EditFormProps>(props => {
    const [city, setCity] = React.useState("");
    return <form onSubmit={e => { e.preventDefault(); props?.onSubmit(city); }}>
        <input value={city} onChange={e => setCity(e.target.value)} />
        <button type="submit">Get</button>
    </form>
});

function App() {
    const [city, setCity] = React.useState("");
    const onSubmit = React.useCallback((city: string) => {
        setCity(city);
    }, [setCity]);

    return (<div>
        <h2>Hello, vibe.d!</h2>
        <EditForm onSubmit={onSubmit} />
        <Weather city={city} />
    </div>);
}

ReactDOM.render(<App />, document.getElementById("app"));
