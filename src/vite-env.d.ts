/// <reference types="vite/client" />

declare global {
  interface Window {
    __openImage: (src: string, alt: string) => void;
  }
}

export {}