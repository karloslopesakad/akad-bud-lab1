export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24 bg-gradient-to-b from-akad-blue to-akad-orange">
      <div className="text-center">
        <h1 className="text-6xl font-bold text-white mb-4">
          🚀 Hello World
        </h1>
        <p className="text-xl text-gray-100 mb-8">
          AKAD BUD Lab - Next.js + Infrastructure as Code
        </p>
        <div className="bg-white/10 backdrop-blur-md rounded-lg p-8 max-w-md">
          <p className="text-white text-lg">
            Bem-vindo ao laboratório de inovação da AKAD!
          </p>
          <p className="text-gray-200 mt-4">
            Este projeto combina Next.js com CloudFormation para deploy automático em ECS Fargate.
          </p>
        </div>
      </div>
    </main>
  );
}
