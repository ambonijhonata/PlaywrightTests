import { JSONPath } from 'jsonpath-plus';
import type { ScenarioContext } from '../context/scenario-context.js';

const wholeVariablePattern = /^\{([^{}]+)\}$/;

export function parseJson(value: string, context: ScenarioContext): unknown {
  return replaceVariables(JSON.parse(value), context);
}

function replaceVariables(value: unknown, context: ScenarioContext): unknown {
  if (typeof value === 'string') {
    const variableOnly = wholeVariablePattern.exec(value);
    return variableOnly ? context.get(variableOnly[1]) : context.replace(value);
  }
  if (Array.isArray(value))
    return value.map((item) => replaceVariables(item, context));
  if (value !== null && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value).map(([key, item]) => [
        key,
        replaceVariables(item, context)
      ])
    );
  }
  return value;
}
export function readJsonPath(body: unknown, path: string): unknown {
  const value = readOptionalJsonPath(body, path);
  if (value === undefined)
    throw new Error(`JSONPath did not find a value: ${path}`);
  return value;
}

export function readOptionalJsonPath(body: unknown, path: string): unknown {
  if (path === '$') return body;
  const values = JSONPath({
    path: path.startsWith('$') ? path : `$.${path}`,
    json: body as object | null
  });
  return Array.isArray(values) ? values[0] : undefined;
}
