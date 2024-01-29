import pandas as pd
import matplotlib.pyplot as plt



df = pd.read_csv('Terraria.csv')

plt.figure(figsize=(8, 8))
plt.pie(df['DPS (SINGLE TARGET)'], labels=df['NAME'], autopct='%1.1f%%')
plt.title('Круговая')
plt.show()
