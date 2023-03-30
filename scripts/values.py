import re

import yaml


def build_label(value: any, prev_key: str) -> str:
	# handle dict (recursion)
	if value.__class__ == dict:
		agg = ''
		if len(value) == 0:
			# no items in the dict
			return prev_key + '={}'
		# recurse over items
		if len(prev_key) > 0:
			prev_key = prev_key + '.'
		for key in sorted(value):
			agg += build_label(value[key], prev_key + "'" + key + "'") + '\n'
		return re.sub(r'\n+', lambda m: '\n', agg.strip('\n'))
	# handle list (recursion)
	elif value.__class__ == list:
		agg = ''
		if len(value) == 0:
			# no items in the list
			return prev_key + '=[]'
		# recurse over items
		if len(prev_key) > 0:
			prev_key = prev_key + '.'
		for i, item in enumerate(value):
			agg += build_label(item, prev_key + str(i)) + '\n'
		return re.sub(r'\n+', lambda m: '\n', agg.strip('\n'))

	# handle other types (non-recursion)
	elif value.__class__ == bool:
		return prev_key + '=bool'
	elif value.__class__ == str:
		return prev_key + '=str'
	elif value.__class__ == float:
		return prev_key + '=float'
	elif value.__class__ == int:
		return prev_key + '=int'
	elif value is None:
		return prev_key + '=null'
	else:
		print(f'Got unexpected type for key "{prev_key}": "{value.__class__}"')
		raise Exception


# workbench
with open('charts/rstudio-workbench/values.yaml', 'r') as file:
	val = yaml.safe_load(file)

with open('workbench-values.txt', 'w') as f:
	print(build_label(val, ''), file=f)

# connect
with open('charts/rstudio-connect/values.yaml', 'r') as file:
	val = yaml.safe_load(file)

with open('connect-values.txt', 'w') as f:
	print(build_label(val, ''), file=f)

# package-manager
with open('charts/rstudio-pm/values.yaml', 'r') as file:
	val = yaml.safe_load(file)

with open('pm-values.txt', 'w') as f:
	print(build_label(val, ''), file=f)
