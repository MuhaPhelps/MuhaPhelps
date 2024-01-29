import pandas as pd
import matplotlib.pyplot as plt



df = pd.read_csv('Terraria.csv')

plt.figure(figsize=(8, 6))
plt.bar(df['NAME'], df['DPS (SINGLE TARGET)'], color=['orange'])
plt.xlabel('DPS (SINGLE TARGET)')
plt.ylabel('NAME')
plt.title('Столбчатая')
plt.xticks(rotation=45)
plt.show()
