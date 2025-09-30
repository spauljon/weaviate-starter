import type { Properties } from "weaviate-client";

export interface Collections {
  Notes: Note;
  Patients: Patient;
}

export interface Note extends Properties {
  title: string;
  body: string;
}

export interface Patient extends Properties {
  name: string;
  age: number;
}

export type VectorizerKind = "openai" | "selfProvided";

export const REGISTRY: { [K in keyof Collections]: { vectorizer: VectorizerKind } } = {
  Notes:    { vectorizer: "openai" },
  Patients: { vectorizer: "selfProvided" },
} as const;
