# Import required libraries for interactive dashboard
import pandas as pd
import plotly.express as px
from dash import Dash, dcc, html, Input, Output

# Initialize Dash app
app = Dash(__name__)

# Load data
def load_data(file_path):
    try:
        df = pd.read_csv(file_path)
        print("Data loaded for dashboard")
        return df
    except Exception as e:
        print(f"Error loading data: {e}")
        return None

# Layout for the dashboard
def create_dashboard_layout(df):
    if df is None:
        return html.Div("Error: No data available")
    
    return html.Div([
        html.H1("ITF Group Loan Risk Dashboard", style={'textAlign': 'center'}),
        
        # Risk Score Distribution
        dcc.Graph(
            id='risk-histogram',
            figure=px.histogram(df, x='risk_score', nbins=20, title='Risk Score Distribution')
        ),
        
        # Loan Amount vs Risk Score
        dcc.Graph(
            id='loan-scatter',
            figure=px.scatter(df, x='loan_amount', y='risk_score', title='Loan Amount vs Risk Score')
        ),
        
        # Credit Score vs Risk Score with filter
        html.Label("Filter by Risk Score Range:"),
        dcc.RangeSlider(
            id='risk-slider',
            min=0,
            max=100,
            step=1,
            value=[0, 100],
            marks={i: str(i) for i in range(0, 101, 20)}
        ),
        dcc.Graph(id='credit-scatter')
    ])

# Callback for dynamic filtering
@app.callback(
    Output('credit-scatter', 'figure'),
    Input('risk-slider', 'value')
)
def update_credit_scatter(risk_range):
    df = load_data('data/loan_data.csv')
    if df is None:
        return px.scatter(title="No data available")
    filtered_df = df[(df['risk_score'] >= risk_range[0]) & (df['risk_score'] <= risk_range[1])]
    return px.scatter(filtered_df, x='credit_score', y='risk_score', title='Credit Score vs Risk Score')

# Main execution
if __name__ == "__main__":
    df = load_data('data/loan_data.csv')
    app.layout = create_dashboard_layout(df)
    app.run_server(debug=True)